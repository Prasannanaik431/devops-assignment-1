# DevOps Engineer – Round 2 Assignment

## Task Title
**Build a CI/CD pipeline for a sample microservice / ML service using GitHub Actions or Jenkins (candidate's choice).**

> Use a public GitHub repo for submission (e.g. `ci-cd-pipeline-<yourname>`). The candidate must push all code and CI configuration to the public repo.

---

## Objective
Design and implement a production-grade continuous integration and continuous delivery pipeline for a simple application (sample app provided or candidate's own small service). The goal is to evaluate the candidate's practical knowledge of CI/CD, secure build pipelines, automated testing, containerization, and release practices.

---

## Requirements (must have)
1. **Source repository**
   - Public GitHub repository named: `ci-cd-pipeline-<yourname>`
   - Clear README with setup & run instructions

2. **CI Pipeline (mandatory)**
   - Use **GitHub Actions** OR **Jenkins** (chooses one)
   - Build step: install deps, run lint/static analysis
   - Test step: run unit tests and (optionally) integration tests
   - Security step: vulnerability scan (`SonarQube`, `trivy`)
   - Build artifact: container image push to DockerHub (or GitHub Container Registry) with immutable tag (e.g., `sha256` or `gitsha`)
   - Optional: Build and publish package/artifact to artifact registry

3. **CD Pipeline (mandatory)**
   - Deploy to a staging environment automatically on merge to `main` (or `staging` branch) **or** on a specific tag
   - Manual approval gate for production deployment (explicit human approval)
   - Production deploy triggered by tag `v*.*.*` or via protected release process

4. **Enterprise-grade practices**
   - Branching strategy: feature branches → PR → code review → protected main branch
   - Protected branches and required status checks
   - Signed commits or enforced code owner reviews for critical paths (documented)
   - Use secrets management (GitHub Secrets or Jenkins Credentials) — no secrets in repo
   - Observability hooks: deploy notifications (email), health checks, basic monitoring hooks (Prometheus/Grafana or alerts)
   - Logging and error aggregation (recommendation: Loki/ELK)

5. **Deliverables**
   - Public GitHub repo with:
     - Source code for a simple service (example: Flask/FastAPI, NodeJS express, or simple microservice)
     - Dockerfile and any build scripts
     - CI workflow file (GitHub Actions YAML) or Jenkinsfile
     - README explaining how to run locally + CI/CD design
     - Documentation/diagrams for branching strategy, secrets handling, and rollback
 

---

## Bonus (extra credit)
- Add acceptance tests / E2E tests
- Deployment automation to Kubernetes cluster (Helm chart or k8s manifests)
- Canary or blue/green deployment strategy implemented
- SAST (e.g., semgrep) + DAST scan
- Automated security scans and license checks
- Add artifact signing (e.g., cosign) and image provenance
- Unit tests and >= 80% coverage, with coverage report upload in CI

---

## Success Criteria & Evaluation Rubric

| Category        | Excellent (5) | Good (3) | Poor (1) |
|-----------------|---------------|----------|----------|
| Functionality   | Fully automated CI, staging + gated prod CD, rollback | CI passes, simple CD to staging only | Manual build, no CD |
| Security        | Secrets, SAST, dependency scanning, signed artifacts | Some scanning + secrets in place | No scanning, secrets in repo |
| Reliability     | Tests, retries, healthchecks, rollback | Basic tests present | No tests |
| Reproducibility | Dockerized + IaC + clear README + one-click deploy | Dockerfile + README | Hard to run locally |
| Documentation   | Architecture diagrams, step-by-step runbook | README present | Minimal docs |

---

## Candidate instructions (what to submit)
1. Create a **public GitHub repo** named `ci-cd-pipeline-<yourname>`.
2. Implement the solution using either **GitHub Actions** or **Jenkins**.
3. Include a short `README.md` with:
   - How to run locally.
   - How CI runs (what checks), and how CD deploys.
   - Any credentials required and how they were mocked/secured.
4. Push final changes and share the repo link via email by the deadline specified by the recruiter/interviewer.

---

## Submission details
- Reply to the interview email with your public GitHub repository link.
- Ensure CI runs on first push and status checks are visible on the repo.
- Provide any auxiliary links (container registry image, deployed staging URL) in README.

---

## Enterprise checklist (detailed steps to implement pipeline)
1. **Repository & Branching**
   - Create `main`, `develop`, and feature branches (`feature/<name>`).
   - Protect `main` (require PR reviews, require CI status checks).

2. **Local dev environment**
   - Provide `Dockerfile`, `docker-compose.yml` (if multi-service).
 
3. **Static analysis & Linting**
   - Add linters (flake8/black for Python, eslint for JS).
   - Fail build when lint fails.

4. **Unit & Integration tests**
   - Use pytest / jest and include test reports; fail CI on failure.

5. **Security**
   - Dependency scan (scan during CI).
   - SAST (e.g., semgrep) as a CI job.
   - Secret scanning in PRs (GitHub secret scanning / pre-commit hooks).

6. **Build & Packaging**
   - Build container image in CI.
   - Tag with `gitsha` or `commit short sha`.
   - Push image to registry (use secrets).

7. **Deployment**
   - Staging: auto-deploy on merge to `develop` or `staging`.
   - Production: manual approval job on semantic version tag.
   - Assume k8s setup is already done and integrated with Argocd. Just update the image in deployment and sync through argocd

8. **Observability & Alerts**
   - Post-deploy status notification (Email).
   - Health-check endpoints and liveness/readiness probes.
   - Basic dashboard or link to logs.
---

## Example Resources to include in your repo
- `.github/workflows/ci-cd.yml` (example included)
- `Jenkinsfile` (example included)
- `Dockerfile`, `docker-compose.yml`
- `k8s/` directory for manifests
- `docs/` with architecture diagram and runbook
- `tests/` with unit tests

---

**Good luck — we expect a clean, secure, and reproducible pipeline.**
