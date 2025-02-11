variable "PWD" {default="" }

group "default" {
  targets = [
    "core",
  ]
}

# NOTE: the context is required for now due to https://github.com/docker/buildx/issues/1028
target "core" {
  target = "core"
  context = "${PWD}"
  platforms = ["linux/amd64", "linux/arm64"]
}
