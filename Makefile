MAKEFILE := $(lastword $(MAKEFILE_LIST))

include shim/.env
include hack/make-bundle-vars.mk

# Current Operator version
VERSION ?= 1.0.0
# Default bundle image tag
IMAGE_TAG_BASE ?= mcg-osd-deployer
BUNDLE_IMG ?= $(IMAGE_TAG_BASE)-bundle:v$(VERSION)

# Options for 'bundle-build'
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)
OUTPUT_DIR ?= bundle
BUNDLE_FLAGS = --output-dir=$(OUTPUT_DIR)

# Image URL to use all building/pushing image targets
IMG ?= $(IMAGE_TAG_BASE):v${VERSION}

# Produce CRDs that work back to Kubernetes 1.11 (no version conversion)
CRD_OPTIONS ?= "crd"

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

OS = $(shell go env GOOS)
ARCH = $(shell go env GOARCH)


all: manager

# Estimate coverage
coverage:
	go tool cover -func coverage.out

# Run linters
lint:
	hack/hooks/pre-commit

# Run tests
ENVTEST_ASSETS_DIR=$(shell pwd)/testbin
setup-envtest:
	mkdir -p $(ENVTEST_ASSETS_DIR); \
	test -f $(ENVTEST_ASSETS_DIR)/setup-envtest.sh || curl -sSLo $(ENVTEST_ASSETS_DIR)/setup-envtest.sh https://raw.githubusercontent.com/kubernetes-sigs/controller-runtime/v0.6.3/hack/setup-envtest.sh; \
	source $(ENVTEST_ASSETS_DIR)/setup-envtest.sh; \
	fetch_envtest_tools $(ENVTEST_ASSETS_DIR); \
	setup_envtest_env $(ENVTEST_ASSETS_DIR)

test: generate fmt vet manifests setup-envtest
	go get golang.org/x/tools/cmd/cover; \
 	KUBEBUILDER_ASSETS=$(ENVTEST_ASSETS_DIR)/bin NOOBAA_CORE_IMAGE={NOOBAA_CORE_IMAGE} NOOBAA_DB_IMAGE={NOOBAA_DB_IMAGE} go test -v -coverprofile coverage.out ./... && \
	$(MAKE) -f $(MAKEFILE) coverage

unit-test: generate fmt vet manifests
	go get golang.org/x/tools/cmd/cover; \
	NOOBAA_CORE_IMAGE={NOOBAA_CORE_IMAGE} NOOBAA_DB_IMAGE={NOOBAA_DB_IMAGE} go test -v -coverprofile coverage.out ./controllers && \
	$(MAKE) -f $(MAKEFILE) coverage

e2e-test: generate fmt vet manifests setup-envtest
	go get golang.org/x/tools/cmd/cover; \
 	KUBEBUILDER_ASSETS=$(ENVTEST_ASSETS_DIR)/bin NOOBAA_CORE_IMAGE={NOOBAA_CORE_IMAGE} NOOBAA_DB_IMAGE={NOOBAA_DB_IMAGE} go test -v -coverprofile coverage.out ./tests && \
	$(MAKE) -f $(MAKEFILE) coverage

# Build manager binary
manager: generate fmt vet
	go build -o bin/manager main.go

# Run against the configured Kubernetes cluster in ~/.kube/config
run: generate fmt vet manifests
	NAMESPACE=${NAMESPACE} ADDON_NAME=${ADDON_NAME} go run ./main.go

# Install CRDs into a cluster
install: manifests kustomize
	$(KUSTOMIZE) build config/crd | kubectl apply -f -
	./shim/shim.sh install
	kubectl create configmap rook-ceph-operator-config -n ${NAMESPACE} --dry-run=client -oyaml | kubectl apply -f -
	echo -e \
	"\napiVersion: v1" \
	"\nkind: Namespace" \
	"\nmetadata:" \
	"\n  labels:" \
	"\n    openshift.io/cluster-monitoring: \"true\"" \
	"\n  name: ${NAMESPACE}" \
	"\nspec: {}" \
	"\n---" \
	"\napiVersion: operators.coreos.com/v1" \
	"\nkind: OperatorGroup" \
	"\nmetadata:" \
	"\n  name: ${NAMESPACE}-operatorgroup" \
	"\n  namespace: ${NAMESPACE}" \
	"\nspec:" \
	"\n  targetNamespaces:" \
	"\n  - ${NAMESPACE}" \
	"\n---" \
	"\napiVersion: operators.coreos.com/v1alpha1" \
	"\nkind: CatalogSource" \
	"\nmetadata:" \
	"\n  labels:" \
	"\n    ocs-operator-internal: 'true'" \
	"\n  name: redhat-operators" \
	"\n  namespace: openshift-marketplace" \
	"\nspec:" \
	"\n  displayName: Openshift Data Foundation" \
	"\n  icon:" \
	"\n    base64data: ''" \
	"\n    mediatype: ''" \
	"\n  image: ${MCG_IMAGE}" \
	"\n  priority: 100" \
	"\n  publisher: Red Hat" \
	"\n  sourceType: grpc" \
	"\n  updateStrategy:" \
	"\n    registryPoll:" \
	"\n      interval: 15m" \
	"\n---" \
	"\napiVersion: operators.coreos.com/v1alpha1" \
	"\nkind: Subscription" \
	"\nmetadata:" \
	"\n  name: odf-subscription" \
	"\n  namespace: ${NAMESPACE}" \
	"\nspec:" \
	"\n  channel: ${CHANNEL}" \
	"\n  name: odf-operator" \
	"\n  source: redhat-operators" \
	"\n  sourceNamespace: openshift-marketplace" | \
	kubectl apply -f -

# Uninstall CRDs from a cluster
uninstall: manifests kustomize
	$(KUSTOMIZE) build config/crd | kubectl delete -f -
	./shim/shim.sh uninstall

# Generate manifests e.g. CRD, RBAC etc.
manifests: controller-gen
	$(CONTROLLER_GEN) $(CRD_OPTIONS) rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases

# Run go fmt against code
fmt:
	go fmt ./...

# Run go vet against code
vet:
	go vet ./...

# Generate code
generate: controller-gen
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

# Build the docker image
docker-build:
	docker build . -t ${IMG}

# Push the docker image
docker-push:
	docker push ${IMG}

# download controller-gen if necessary
controller-gen:
ifeq ($(origin PULL_NUMBER),undefined)
	# [setting up controller-gen for local usage]
	@ { \
	GO111MODULES=off go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.7.0 ;\
	}
CONTROLLER_GEN=$(shell which controller-gen)
else
	# [setting up controller-gen for CI usage]
	@{ \
	set -e ;\
	CONTROLLER_GEN_TMP_DIR=$$(mktemp -d) ;\
	cd $$CONTROLLER_GEN_TMP_DIR ;\
	go mod init tmp ;\
	go get sigs.k8s.io/controller-tools/cmd/controller-gen@v0.7.0 ;\
	rm -rf $$CONTROLLER_GEN_TMP_DIR ;\
	}
CONTROLLER_GEN=$(GOBIN)/controller-gen
endif

# download kustomize if necessary
kustomize:
ifeq (, $(shell which kustomize))
	@{ \
	set -e ;\
	KUSTOMIZE_GEN_TMP_DIR=$$(mktemp -d) ;\
	cd $$KUSTOMIZE_GEN_TMP_DIR ;\
	go mod init tmp ;\
	go get sigs.k8s.io/kustomize/kustomize/v3@v3.9.1 ;\
	rm -rf $$KUSTOMIZE_GEN_TMP_DIR ;\
	}
KUSTOMIZE=$(GOBIN)/kustomize
else
KUSTOMIZE=$(shell which kustomize)
endif

# download etcd if necessary
# requires root privileges
etcd:
	@{ \
		if [[ ! -d "/usr/local/kubebuilder/bin" ]]; then \
            curl -sSLo envtest-bins.tar.gz "https://go.kubebuilder.io/test-tools/1.21.2/linux/amd64" && \
			mkdir /usr/local/kubebuilder && \
            tar -C /usr/local/kubebuilder --strip-components=1 -zvxf envtest-bins.tar.gz && \
            rm envtest-bins.tar.gz; \
		fi \
	}


# Generate bundle manifests and metadata, then validate generated files.
.PHONY: bundle
bundle: manifests kustomize
	operator-sdk generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	cd config/console && $(KUSTOMIZE) edit set image mcg-ms-console=$(MCG_CONSOLE_IMG)
	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS) $(BUNDLE_FLAGS)
	cp config/metadata/* $(OUTPUT_DIR)/metadata/
	operator-sdk bundle validate $(OUTPUT_DIR)

# Build the bundle image.
.PHONY: bundle-build
bundle-build:
	docker build -f bundle.Dockerfile -t $(BUNDLE_IMG) .

.PHONY: opm
OPM = ./bin/opm
opm:
ifeq (,$(wildcard $(OPM)))
ifeq (,$(shell which opm 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPM)) ;\
	curl -sSLo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/v1.15.1/$(OS)-$(ARCH)-opm ;\
	chmod +x $(OPM) ;\
	}
else 
OPM = $(shell which opm)
endif
endif
BUNDLE_IMGS ?= $(BUNDLE_IMG) 
CATALOG_IMG ?= $(IMAGE_TAG_BASE)-catalog:v$(VERSION)
ifneq ($(origin CATALOG_BASE_IMG), undefined)
	FROM_INDEX_OPT := --from-index $(CATALOG_BASE_IMG)
endif 
.PHONY: catalog-build
catalog-build: opm
	$(OPM) index add --container-tool docker --mode semver --tag $(CATALOG_IMG) --bundles $(BUNDLE_IMGS) $(FROM_INDEX_OPT)
.PHONY: catalog-push
catalog-push: ## Push the catalog image.
	$(MAKE) docker-push IMG=$(CATALOG_IMG)
