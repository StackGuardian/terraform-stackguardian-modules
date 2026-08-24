# Private Runner Troubleshooting — ECS agent terminally exits after successful registration

How to approach a customer's private runner that **registers successfully but then fails to run
workflows**, where the ECS agent logs end in a terminal exit.

## Symptom

Runner registers fine, but workflows never pick up. The `ecs-agent` container is not running, and
its log ends with:

```
level=info  msg="Restored from checkpoint file" containerInstanceARN="arn:aws:ecs:<region>:<acct>:container-instance/<cluster>/<INSTANCE_ID>"
level=info  msg="Cluster was successfully restored" cluster="<cluster>"
level=error msg="Unable to register as a container instance with ECS" error="... RegisterContainerInstance ... StatusCode: 400 ... ClientException: Referenced container instance <INSTANCE_ID> not registered."
level=critical msg="Agent will terminally exit, unable to register container instance"
```

## Root cause

The StackGuardian private runner runs the **Amazon ECS agent in external mode**
(`ECS_EXTERNAL=true`) to execute workflow tasks. The agent **persists its registration state** to:

- `/var/lib/ecs/data/agent.db` (boltdb; newer agents) — mounted into the container as
  `ECS_DATADIR=/data/`
- (older agents used `/var/lib/ecs/data/ecs_agent_data.json`)

On startup the agent reads that state, finds the **container-instance ARN from a previous
registration**, and tries to **re-register that same ARN**. If that instance was deregistered on
the ECS / StackGuardian side, ECS returns `400 ... not registered` and the agent **terminally
exits**. Registration "succeeding" earlier doesn't help — the agent can't come back up, so no tasks
run.

This is **state-dependent, not version-dependent.** OS / Docker / installation-script versions are
irrelevant — a matching spec box with clean state works fine.

### When the state goes stale

The local `agent.db` outlives the server-side container instance when, between registrations:

- the runner group is deleted/recreated,
- the node token is rotated,
- the instance is pruned for being offline,
- or `register` is re-run **without** local cleanup,

…and then the host **reboots or the `ecs` service / `ecs-agent` container restarts**.

## Noise to ignore in the log

These are normal and are **not** the failure:

- `Unable to fetch user data: blackholed`, `Not able to get EC2 Instance ID from IMDS`,
  `Unable to get Availability Zone` — expected on an **external** (non-EC2) instance; it uses
  `/rotatingcreds` instead of IMDS.
- The wall of `Docker client version 1.17 … 1.39 is too old … Minimum supported API version is
1.40`, followed by `Setting minimum docker API version newMinAPIVersion=1.40` — expected with
  Docker 28/29.x. The agent negotiates and continues. A **healthy** runner logs the same lines.

The only line that matters is the `critical … terminally exit` on `RegisterContainerInstance`.

## Diagnose (read-only first — confirm before changing anything)

```bash
# 1. Is the agent actually down, and what does it say?
sudo docker ps -a --filter name=ecs-agent --format '{{.Names}}\t{{.Status}}'
sudo docker logs --tail=60 ecs-agent

# 2. Does the persisted state hold a stale ARN matching the one in the 400 error?
sudo strings /var/lib/ecs/data/agent.db 2>/dev/null \
  | grep -o 'container-instance/[^"]*' | sort -u
# (older agents:)
sudo cat /var/lib/ecs/data/ecs_agent_data.json 2>/dev/null \
  | jq '{Cluster: .Data.Cluster, ContainerInstanceArn: .Data.ContainerInstanceArn}'

# 3. Confirm cluster/external config
sudo grep -E 'ECS_CLUSTER|ECS_EXTERNAL|ECS_DATADIR' /etc/ecs/ecs.config
```

If the ARN from step 2 equals the `<INSTANCE_ID>` in the `400 ... not registered` error, it is
conclusively the stale-state issue.

## Fix

**Preferred — supported deregister/reregister cycle.** `deregister -f/--force` runs the script's
`clean_local_setup`, which removes `/var/lib/ecs`, `/etc/ecs`, cached creds, the SSM managed
instance dir, etc., so the next `register` comes up as a fresh instance:

```bash
sudo sg-runner deregister -f \
  --organization "<org>" --runner-group "<runner-group>" --sg-node-token "<token>"

sudo sg-runner register \
  --organization "<org>" --runner-group "<runner-group>" --sg-node-token "<token>"
```

**Minimal fallback** — just clear the stale checkpoint and let the agent register anew:

```bash
sudo docker stop ecs-agent
sudo rm -f /var/lib/ecs/data/agent.db        # older: /var/lib/ecs/data/ecs_agent_data.json
sudo systemctl restart ecs                   # or: sudo docker start ecs-agent
sudo docker logs -f ecs-agent                # expect a NEW registration, no 400
```

### Verify recovery

```bash
sudo docker ps --filter name=ecs-agent --format '{{.Names}}\t{{.Status}}'   # Up (healthy)
sudo docker inspect ecs-agent --format '{{.State.Health.Status}}'           # healthy
```

Then trigger a workflow against the runner group and confirm it picks up.

## Prevention

- Always use `sg-runner deregister -f` (local cleanup) **before** re-registering a host or before
  deleting/recreating its runner group. Re-registering over stale state is what plants the bug.
- After any server-side removal of an instance/runner group, treat the host as needing a clean
  re-register, not just a reboot.

## Reproducing it deliberately (for a captured repro)

A spec-matched box alone will not reproduce it. To force it:

1. Register a runner normally; confirm `ecs-agent` is `Up (healthy)`.
2. Deregister **that container instance** on the StackGuardian/ECS side (or delete & recreate the
   runner group) **without** running local cleanup on the host.
3. `sudo systemctl restart ecs` (or reboot the host).

The agent restores the now-dead ARN from `agent.db`, re-registration returns `400 ... not
registered`, and it terminally exits — identical to the customer log.
