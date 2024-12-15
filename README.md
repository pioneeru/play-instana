# Deploying Instana backend v287

The project is a set of bash scripts to automate Instana deployment on RedHat Openshift (versions: v4.15).

#### 1. Copy `credentials.env.template` to `credentials.env`
The following template is pre-populated with values but will not work as it is.
```bash
cd play-instana
cp credentials.env.template credentials.env
cd ocp
```

#### 2. Specify env credentials with your params
Pay attention to:
* INSTANA_BASE_DOMAIN - used to build instana domains for unit and agent
* SALES_KEY
* DOWNLOAD_KEY
* INSTANA_ADMIN_USER
* INSTANA_ADMIN_PASSWORD
* RWO_STORAGECLASS - for all databases
* RWX_STORAGECLASS - for raw-spans and synthetics
* TLS_CERTIFICATE_GENERATE - set NO if you have your own certificate. Put specified filenames to the same directory.
```bash
vi credentials.env
```

#### 3. Script to uninstall instana
Removes all Instana and datastore artifacts including CRDs and namespaces:
```bash
./0-uninstall.sh
```

#### 4. Nfs provisioner
When there is no other storage available install NFS provisioner. It will create storage class `nfs-client`:
```bash
./1-nfs.sh
```

#### 5. Certificates manager
Instana needs certificate manager if it is not installed yet run:
```bash
./2-cert-manager.sh
```

#### 6. Install/update instana plugin for kubectl
Running the script will install/update instana kubectl plugin of required version:
```bash
./3-kubectl-instana.sh
```

#### 7. To generate initial manifests for instana components run
This script will generate all datastore and instana manifests using parameters specified in `credentials.env`:
```bash
./4-generate_manifests.sh
```
Now, this is the time to edit generated manifests. By default all manifests specified with minimal replicas and minimal resources given for tiny deployment just enough to test installation. It is required to adjust the values in accordance with the load.

#### 8. Download charts for installation
The script is downloading all required helm charts of certain versions for Instana deployment:
```bash
./5-pull_datastore_charts.sh
```

#### 9. install datastores and Instana backend

```bash
./6-install.sh
```
