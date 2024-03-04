# Deploying Instana backend v263_8-1


1. copy `credentials.env.template` to `credentials.env`:
```bash
cd play-instana
cp credentials.env.template credentials.env
cd ocp
```
2. populate credentials env with your params:
```bash
vi ../credentials.env
```
3. if you need to uninstall instana - run:
```bash
./0-uninstall.sh
```
4. if you need to install nfs provisioner - run:
```bash
./1-nfs.sh
```
5. if you need to install cert-manager - run:
```bash
./2-cert-manager.sh
```
6. install instana plugin for kubectl - run:
```bash
./3-kubectl-instana.sh
```
7. if you do not have manifests for instana components - run:
```bash
./4-generate_manifests.sh
```
8. download charts - run:
```bash
./5-pull_datastore_charts.sh
```
9.  install datastores and Instana backend - run:
```bash
./6-install.sh
```
