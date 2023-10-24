# play-instana

1. copy `credentials.env.template` to `credentials.env`
2. populate credentials env with your params
3. if you need to uninstall instana - run `0-uninstall.sh`
4. if you need to install nfs provisioner - run `1-nfs.sh`
5. if you need to install cert-manager - run `2-cert-manager.sh`
6. install instana plugin for kubectl - run `3-kubectl-instana.sh`
7. if you do not have manifests for instana components - run `4-generate_manifests.sh`
8. download charts - run `5-pull_datastore_charts.sh`
9. install datastores and Instana backend - run `6-install.sh`
