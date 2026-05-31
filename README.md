# Deploying Instana backend v317

The project is a set of bash scripts to automate Self-Hosted Custom Instana Edition deployment on RedHat Openshift. Tested with the following configurations:
- OCP version: v4.20, v4.21
- Node architecture: amd64, ppc64le, s390x


#### 1. Clone the project and copy `credentials.env.template` to `credentials.env`
The following template is pre-populated with values but will not work as it is.
```bash
git clone https://github.com/pioneeru/play-instana.git
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
* TLS_CERTIFICATE_GENERATE - set NO if you have your own certificate. Put specified filenames to the same directory with executable scripts (play-instana/ocp/).
* CUSTOM_CONFIGS_FOLDER - use for customizations (outside of the git project to keep them during upgrades)
```bash
vi ../credentials.env
```

#### 3. Script to uninstall instana
Removes all Instana and datastore artifacts including CRDs and namespaces:
```bash
./0-uninstall.sh
```

#### 4. Download required packets
- When there is no other storage available configure NFS server and specify NFS credentials in `credentials.env` to download helm chart of NFS provisioner.
- Instana needs certificate manager it will be downloaded as well as instana datastore helm charts.
- Instana kubectl plugin will be downloaded
- yq package is required to merge yaml files during generation final CR manifests, so it will be downloaded
- current license will be downloaded based on sales key specified in `credentials.env`

Execute the following script to download:
```bash
./1-download_tools_and_charts.sh
```

#### 5. (Optional) Push images to local registry and copy project to bastion node for air-gapped deployment
If you use air-gapped deployment you need to have access to local registry. The following script will pull images from IBM image registry re-tag them and push to your local registry. Set `${INSTANA_IMAGE_REGISTRY}` in `credentials.env` pointing to local registry, Instana cluster will use `${INSTANA_IMAGE_REGISTRY}` to pull images for its containers:
```bash
./1-push_images_to_local_registry.sh
```
The scripts pulls images from `artifact-public.instana.io` and pushes them into `${INSTANA_IMAGE_REGISTRY}` specified in `credentials.env`.

By default `${INSTANA_AIRGAPPED_FOLDER}` specified in `credentials.env` points to a directory in the project. 
For air-gapped deployment copy entire project to your bastion node including downloaded files in a folder set as `${INSTANA_AIRGAPPED_FOLDER}` in `credentials.env`:
```bash
scp -r play-instana username@bastion_host:/path/to/destination/
```

#### 6. Install/update tools on bastion node
This script will install or update required tools (helm, kubectl plugin, yq) on your bastion node. Running the script will install/update instana kubectl plugin, helm and yq:
```bash
./2-install_tools_on_bastion.sh
```

#### 7. Install prerequisites for Instana deployment on the cluster
The script will install required prerequisites on the cluster: certification manager and nfs provisioner (if NFS server address defined in `credentials.env`):
```bash
./3-install-prerequisites_on_cluster.sh
```

#### 8. To generate initial manifests for instana components
This script will generate all datastore and instana CR manifests using parameters specified in `credentials.env`. Base yaml files will be generated using specified cluster platform. They will be merged with custom configs from `${CUSTOM_CONFIGS_FOLDER}` specified in `credentials.env`. Keep the folder outside of the project to be able to copy new version of the the project for Instana updates without affecting custom configs:
```bash
./4-generate_manifests.sh
```
If you install Instana from scratch, after running the script review generated manifests in "play-instana/ocp". By default all manifests generated with minimal replicas and minimal resources given for tiny deployment just enough to test installation. It is required to adjust the values in accordance with the load, so copy the manifests to folder `${CUSTOM_CONFIGS_FOLDER}` specified in `credentials.env` and adjust values there.

#### 9. install datastores and Instana backend
Once you made all changes in `credentials.env` and custom manifest files apply the changes to Install or upgrade Instana backend and datastores:
```bash
./5-apply-changes.sh
```
