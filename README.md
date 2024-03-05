# Deploying Instana backend v265_4-1

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

3. To uninstall instana:

```bash
./0-uninstall.sh
```

4. To use nfs provisioner install nfs client:

```bash
./1-nfs.sh
```

5. To install cert-manager:

```bash
./2-cert-manager.sh
```

6. Install/update instana plugin for kubectl:

```bash
./3-kubectl-instana.sh
```

7. To generate initial manifests for instana components run:

```bash
./4-generate_manifests.sh
```

8. Download charts for installation:

```bash
./5-pull_datastore_charts.sh
```

9. install datastores and Instana backend:

```bash
./6-install.sh
```
