# play-instana


1. copy `credentials.env.template` to `credentials.env`
3. populate credentials env with your params
4. if you need to uninstall instana - run `0-uninstall.sh`
5. if you need to install nfs provisioner - run `1-nfs.sh`
6. if you need to install cert-manager - run `2-cert-manager.sh`
7. install instana plugin for kubectl - run `3-kubectl-instana.sh`
8. if you do not have manifests for instana components - run `4-generate_manifests.sh`
9. download charts - run `5-pull_datastore_charts.sh`
10. install datastores and Instana backend - run `6-install.sh`
