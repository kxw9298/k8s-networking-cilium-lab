# Labs

One folder per lab, numbered by week, for example `w1-manual-pod-networking/` or `w3-cilium-l7-policy/`.

Each lab folder holds:

- `README.md` with the goal, the steps you ran, what you observed (command output, Hubble flows, diagrams), and what you'd do in production
- the scripts and manifests needed to reproduce it from a fresh kind cluster

Keep each lab reproducible: someone should be able to clone the repo, run the setup, and repeat it.
