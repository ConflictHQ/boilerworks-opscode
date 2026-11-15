# From a new account to a deployed boilerworks app

One path from an empty cloud account to a running boilerworks template app on
[Astrolift](https://astrolift.dev), with its Storybook in the
[Calliope AI UX front door](https://github.com/calliopeai/calliope-ux). The
reference template is
[boilerworks-nestjs-nextjs](https://github.com/ConflictHQ/boilerworks-nestjs-nextjs)
("The Calliope AI happy path" in its README); `boilerworks-django-nextjs` and
`boilerworks-fastapi-nextjs` ship the same three manifests.

This page was written from the code and docs of the repos it links, without
running Terraform, Helm or any cloud CLI. Steps marked **unverified** are not
confirmed by the code; check them before relying on them. Gaps are listed at
the end.

## Read this first: which repo installs what

| Repo | What it provisions | Installs Astrolift? |
|------|--------------------|---------------------|
| `boilerworks-opscode` (this repo) | A generic app environment per cloud: network, Postgres, Redis, object storage, secrets, DNS, and one container runtime (ECS/EKS, Cloud Run/GKE, Container Apps/AKS) | No |
| [calliopeai/astrolift-opscode](https://github.com/calliopeai/astrolift-opscode) (private) | The Astrolift control plane and a tenant cluster per cloud, plus the Helm charts | Yes, the self-hosted recipe |
| [calliopeai/calliope-installer](https://github.com/calliopeai/calliope-installer) (private) | Managed and BYOC Astrolift installs, applied by an in-account agent | Yes (**unverified**: not read for this page) |
| [calliopeai/calliope-opscode](https://github.com/calliopeai/calliope-opscode) (private) | Calliope's own estate and the JunoHub/Workbench customer provisioner; hosts the installer distribution and park/unpark scripts | No |

The happy-path templates deploy on Astrolift, so the account needs Astrolift,
and that comes from astrolift-opscode (or the installer), not from this repo.
This repo's stacks are the route for running a boilerworks app directly on
cloud services without Astrolift, and, optionally, the source of a Kubernetes
cluster that Astrolift then registers (step 1c).

## Prerequisites

- Admin access to the new account (AWS account, GCP project or Azure subscription).
- A DNS zone you own in that cloud (Route53, Cloud DNS or Azure DNS), delegated from the registrar.
- Terraform >= 1.5 (astrolift-opscode pins 1.9), `kubectl`, `helm` >= 3.12, and the cloud CLI (`aws`, `gcloud` or `az`).
- A Temporal server reachable from the account (the Astrolift recipe requires `temporal_address` and does not ship one).
- The `astro` CLI ([calliopeai/astrolift](https://github.com/calliopeai/astrolift), `astrolift-cli/`).
- A GitHub organization with the Astrolift GitHub App installed on the app's repository. `astro app register` refuses a repo that is not in the organization's GitHub App installation.
- Write access to [calliopeai/calliope-ux](https://github.com/calliopeai/calliope-ux) for the front door entry.

## 1. Provision the account

Pick one of the two. For the happy path, take 1a.

### 1a. With Astrolift (happy path)

Follow the astrolift-opscode runbook for the cloud, which is authoritative.
Read its `STATUS.md` first: every cloud root is marked "wired, not apply-tested",
and AWS is the recommended production path.

| Cloud | Runbook | Control plane | Tenant cluster |
|-------|---------|---------------|----------------|
| AWS | `INSTALL-aws.md` | ECS Fargate | EKS (`enable_eks = true`) |
| GCP | `INSTALL-gcp.md` | Cloud Run | GKE Autopilot (`enable_gke = true`) |
| Azure | `INSTALL-azure.md` | Container Apps | AKS (`enable_aks = true`) |
| Any Kubernetes | `INSTALL-k8s-native.md` | `helm/astrolift` chart | the same cluster |

The cloud runbooks share the same sections: prerequisites, `config.env`,
infra identity, state backend, `terraform.tfvars` (copy
`<cloud>/environments/<env>/terraform.tfvars.example`; `base_domain`,
`container_image` and `temporal_address` are required), plan, apply,
verify, first boot (§9), register the tenant cluster (§10) and first app (§11).
The tenant cluster must have `enable_eks`/`enable_gke`/`enable_aks` set,
since an app deploys onto a registered cluster.

At first boot (§9) set `ASTROLIFT_ADMIN_EMAIL`, `ASTROLIFT_ORG_SLUG` and
`ASTROLIFT_ORG_NAME` on the control plane; the first sign-in with that email
becomes the org owner. Then register the cluster with
`python manage.py register_tenant_cluster ... --plugin-slug <aws|gcp|azure> --auto-discover-<cloud>`
and run `astro cluster bootstrap --cluster-slug <slug>` (§10), which installs
the `astrolift-prereqs` chart.

### 1b. Without Astrolift (this repo)

This route runs one container per environment on cloud services. It is not the
happy path: the template's three Astrolift manifests are not used, and the
template images do not match the runtime's defaults (see Gaps).

| Cloud | Status | Directory | Variables that exist |
|-------|--------|-----------|----------------------|
| AWS | Production ready | `aws/environments/{dev,stg,prd}` | `region`, `enable_ecs`, `enable_eks`, `container_image`, `ecs_task_cpu`, `ecs_task_memory`, `db_instance_class`, `redis_node_type`, `allowed_bastion_ips`, `bastion_key_name` |
| GCP | Experimental, dev only | `gcp/environments/dev` | `project_id` (required), `region`, `enable_cloud_run`, `enable_gke`, `container_image`, `db_tier`, `redis_memory_size_gb` |
| Azure | Experimental, dev only | `azure/environments/dev` | `location`, `resource_group_name`, `enable_container_apps`, `enable_aks`, `container_image`, `container_cpu`, `container_memory`, `postgres_sku`, `redis_sku`, `redis_family`, `redis_capacity` |

AWS, per [bootstrap.md](../bootstrap.md):

1. Edit `aws/config.env` (`PROJECT`, `AWS_REGION`, `OWNER`). Also edit the
   `locals` block in `aws/environments/<env>/main.tf` (`name`, `service_name`,
   `owner`, `domain`): resource names and the domain are set there, not from
   `config.env`.
2. Deploy `aws/cloudformation/infra-user.yml` and configure the profile it outputs.
3. `./run.sh bootstrap aws <env|all>` (S3 + DynamoDB state backend, then init).
4. Set `container_image` (and the other variables above) in a `terraform.tfvars`
   in the environment directory.
5. `./run.sh plan aws <env>`, review, then `./run.sh apply aws <env>`.
6. `./aws/scripts/cold-boot.sh <env>`.

GCP and Azure: apply `gcp/tf-backend` (variable `project_id`, `region`) or
`azure/tf-backend` (`resource_group_name`, `location`, `project_name`) first,
then uncomment and fill the `backend` block in the environment's `main.tf` and
run `terraform init`, `plan` and `apply` in `gcp/environments/dev` or
`azure/environments/dev` with a `terraform.tfvars`. **Unverified:** these roots
have not been applied against a live project or subscription, and `run.sh`
init/plan for them does not work as written (see Gaps).

### 1c. Optional: use a cluster from this repo as the Astrolift tenant

**Unverified.** `INSTALL-k8s-native.md` §1 lists "existing managed cluster
(EKS/GKE/AKS without our cloud-side IaC)" as a supported starting point, so a
cluster created here with `enable_eks`, `enable_gke` or `enable_aks` can in
principle be registered with an Astrolift control plane
(`register_tenant_cluster --plugin-slug k8s_native --auth-method service_account_token ...`,
then `astro cluster bootstrap`). Do not also run this repo's
`kubernetes/base/install.sh` on it: that installs Gateway API, Envoy Gateway
and Argo CD, while `astrolift-prereqs` installs ingress-nginx (ALB on AWS),
cert-manager and external-dns, and nothing reconciles the two baselines.

## 2. Log in and pick a project

```shell
astro server add <server-slug> <api-url>
astro server use <server-slug>
astro auth login              # browser device flow
astro org use <org-slug>
astro project list --json     # the project GUID for --project-id
```

## 3. Generate and rename the app

1. Create the app from the template (`boilerworks new <template>`, or clone it).
2. Rename it, per the template README's "Rename the product": `apps/web/ui-app/product.ts`,
   `apps/web/ui-app/shell/AppFrame.tsx`, and `boilerworks-app` in all three
   manifests (`name`, `slug`, `display_name`, `repo`, the managed service names).
3. In `storybook/astrolift.toml`, replace the `[ingress]` and `[ingress.auth]`
   values: they point at the CONFLICT cluster's central auth.
4. Push the repo to a GitHub organization covered by the Astrolift GitHub App.

## 4. Register and deploy the three apps

Astrolift builds one image per app, so the template has three manifests:

| Manifest | App | Builds | Port | Health |
|----------|-----|--------|------|--------|
| `astrolift.toml` | API, with managed Postgres and Redis bound as `DATABASE_URL` and `REDIS_URL` | `apps/api/Dockerfile` | 4000 | `/health` |
| `apps/web/astrolift.toml` | Next.js web | `apps/web/Dockerfile` | 3000 | `/auth/login` |
| `storybook/astrolift.toml` | Storybook (nginx) | `storybook/Dockerfile`, from the repo root | 8080 | `/healthz` |

```shell
astro app register --project-id <project-guid> --source-repo <org>/<repo>
astro app register -f apps/web/astrolift.toml --manifest-path apps/web/astrolift.toml \
  --project-id <project-guid> --source-repo <org>/<repo>
astro app register -f storybook/astrolift.toml --manifest-path storybook/astrolift.toml \
  --project-id <project-guid> --source-repo <org>/<repo>
```

`register` also wires CI (webhook, repo secrets and an
`.github/workflows/astrolift-app-<guid>.yml` per app); `astro ci setup <app-slug>`
redoes it. If the web app builds from the wrong directory, set it with
`astro app set-build-context <web-app-slug> apps/web`.

Secrets on the API (the template README names only the first; the others are
read by `apps/api` for nestjs-nextjs):

```shell
astro app secrets create SESSION_SECRET <api-app-slug> --stdin
astro app secrets create CORS_ORIGINS <api-app-slug> --stdin    # the web app's public URL
astro app secrets create AUTH0_DOMAIN <api-app-slug> --stdin    # and AUTH0_CLIENT_ID, AUTH0_CLIENT_SECRET
```

The web bundle needs the API's public URL at build time as the build argument
`NEXT_PUBLIC_API_ROOT`. There is no manifest key or `astro app` flag for build
arguments; they are the `buildArgs` field of the `updateApp` GraphQL mutation
(`astro api graphql`), after which the app's workflow must be re-synced.
**Unverified** end to end.

Pushes to `main` then deploy all three apps through the managed workflows.
A manual deploy is `astro app deploy --env <env> --image-tag <tag> --wait`;
watch with `astro app show`, `astro app events` and `astro app logs`.

## 5. Add the Storybook to the front door

Once the Storybook app is deployed, add an entry to `catalogs.json` in
[calliopeai/calliope-ux](https://github.com/calliopeai/calliope-ux), run
`npm test` there (it validates `id`, `title`, `kind` and `upstream`), and push:

```json
{
  "id": "<app-slug>",
  "title": "<App title>",
  "group": "web",
  "kind": "storybook",
  "repo": "<org>/<repo>",
  "app": "storybook-<app-slug>",
  "upstream": "web.<namespace>.svc.cluster.local:8080"
}
```

The front door proxies the upstream inside the cluster, so the Storybook must
run on the same cluster as the front door app. Existing entries use the
namespace `conflict-<storybook app slug>`; the workload is `web`. For another
org or cluster the namespace prefix differs (**unverified**).

## Gaps

- **No single repo provisions an Astrolift account.** This repo does not install
  Astrolift; astrolift-opscode and calliope-installer do, and calliope-opscode is
  not part of the path. Nothing links this repo's clusters to an Astrolift
  control plane (step 1c is unverified and the base platforms conflict).
- **Manual first boot.** Astrolift admin, org and URL variables are set by hand on
  the control plane; cluster registration is a `manage.py` command, with no
  `astro cluster register`.
- **No Temporal** ships with the Astrolift recipe, and no recipe root is
  apply-tested in CI.
- **Hardcoded names in this repo.** `name`, `service_name`, `owner` and `domain`
  (`dev-boilerworks`, `dev.boilerworks.net`) are `locals` in every environment's
  `main.tf`, and `kubernetes/base/install.sh` defaults the cluster name to
  `<env>-boilerworks`; `aws/config.env` only drives the state backend names.
- **`run.sh` is AWS-shaped.** It always passes S3/DynamoDB backend flags and
  `-var=region`; the GCP and Azure backends are commented out, there is no
  `gcp/config.env` or `azure/config.env`, Azure has `location` instead of
  `region`, and GCP's required `project_id` is not passed.
- **No environment-root outputs.** The `ecs/`, `eks/`, `gke/` and `aks/`
  submodule outputs are not re-exported, and the EKS ALB controller role that
  `kubernetes/base/install.sh --alb-role-arn` needs is not an output at all.
- **Runtime defaults do not fit the templates.** ECS expects port 8000 and
  `/health/`; the nestjs-nextjs API listens on 4000 with `/health`, and a
  template is three images while each runtime here runs one.
- **App registration is manual.** Three `astro app register` runs with a project
  GUID; the boilerworks CLI does not register them yet (calliope-ux#8).
- **Build arguments have no CLI or manifest path.** `NEXT_PUBLIC_API_ROOT` needs
  a GraphQL mutation and a workflow re-sync, and the API URL is only known after
  the API deploys.
- **Undeclared secrets.** `CORS_ORIGINS` and the Auth0 variables are not in the
  manifest or the README's command list; migrations on deploy are not confirmed.
- **Every push rebuilds all three apps;** the managed workflows have no path filters.
- **Cluster-specific values in the template.** The Storybook manifest's ingress
  auth and the front door's `conflict-` namespace prefix are tied to the CONFLICT
  cluster.
- **The front door entry is manual**, and calliope-ux CI does not run its own
  `npm test` on push.
