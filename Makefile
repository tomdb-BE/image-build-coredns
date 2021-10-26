SEVERITIES = HIGH,CRITICAL

ifeq ($(ARCH),)
ARCH=$(shell go env GOARCH)
endif

BUILD_META ?= -multiarch-build$(shell date +%Y%m%d)
ORG ?= rancher
PKG_COREDNS ?= github.com/coredns/coredns
SRC_COREDNS ?= github.com/coredns/coredns
PKG_AUTOSCALER ?= github.com/kubernetes-sigs/cluster-proportional-autoscaler
SRC_AUTOSCALER ?= github.com/kubernetes-sigs/cluster-proportional-autoscaler 
TAG ?= v1.8.5$(BUILD_META)
UBI_IMAGE ?= centos:7
GOLANG_VERSION ?= v1.16.7b7-multiarch
export DOCKER_BUILDKIT?=1

AUTOSCALER_BUILD_TAG := $(TAG:v%=%)

.PHONY: image-build-coredns
image-build-coredns:
	docker build \
		--build-arg PKG=$(PKG_COREDNS) \
		--build-arg SRC=$(SRC_COREDNS) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
                --build-arg ARCH=$(ARCH) \
                --build-arg GO_IMAGE=$(ORG)/hardened-build-base:$(GOLANG_VERSION) \
                --build-arg UBI_IMAGE=$(UBI_IMAGE) \
		--target coredns \
		--tag $(ORG)/hardened-coredns:$(TAG) \
		--tag $(ORG)/hardened-coredns:$(TAG)-$(ARCH) \
	.

.PHONY: image-push-coredns
image-push-coredns:
	docker push $(ORG)/hardened-coredns:$(TAG)-$(ARCH)

.PHONY: image-manifest-coredns
image-manifest-coredns:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-coredns:$(TAG) \
		$(ORG)/hardened-coredns:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-coredns:$(TAG)

.PHONY: image-scan-coredns
image-scan-coredns:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-coredns:$(TAG)

.PHONY: image-build-autoscaler
image-build-autoscaler:
	docker build \
		--build-arg PKG=$(PKG_AUTOSCALER) \
		--build-arg SRC=$(SRC_AUTOSCALER) \
		--build-arg TAG=$(AUTOSCALER_BUILD_TAG:$(BUILD_META)=) \
                --build-arg ARCH=$(ARCH) \
                --build-arg GO_IMAGE=$(ORG)/hardened-build-base:$(GOLANG_VERSION) \
                --build-arg UBI_IMAGE=$(UBI_IMAGE) \
		--target autoscaler \
		--tag $(ORG)/hardened-cluster-autoscaler:$(TAG) \
		--tag $(ORG)/hardened-cluster-autoscaler:$(TAG)-$(ARCH) \
	.

.PHONY: image-push-autoscaler
image-push-autoscaler:
	docker push $(ORG)/hardened-cluster-autoscaler:$(TAG)-$(ARCH)

.PHONY: image-manifest-autoscaler
image-manifest-autoscaler:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-cluster-autoscaler:$(TAG) \
		$(ORG)/hardened-cluster-autoscaler:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-cluster-autoscaler:$(TAG)

.PHONY: image-scan-autoscaler
image-scan-autoscaler:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-cluster-autoscaler:$(TAG)

