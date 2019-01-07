# Kube Watch

[![License: Apache-2.0][Apache 2.0 Badge]][Apache 2.0]
[![GitHub Release Badge]][GitHub Releases]

A [Docker] image packed tool for watching a [Kubernetes] object or its part
invoking a specified handler executable on a change.

## Usage

Consider you have a [ConfigMap]:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-watch-example-configmap
data:
  fruits: orange,apple,banana
```

And you want to run a handling executable on every change of the ".data.fruits"
field. The [Example Manifest] creates all the needed workloads (including the
mentioned ConfigMap) to demonstrate how could it be done with the tool.

Along with the ConfigMap mentioned above the manifest creates another ConfigMap
representing a handling executable which is a script like this:

```
#!/bin/bash

echo "Current fruits: $1"
echo "Previous fruits: $2"
```

Handling executable is invoked with two parameters: the current state of a field
and the previous one. Thus this script just prints out both states.

To connect this script and the target field, the manifest runs the Kube Watch
based container as a [Deployment].

To be able watching the ConfigMap, the Deployment uses a [Service Account] bound
to the corresponding role. The corresponding Role and RoleBinding are also
created.

To see the example in action please apply the manifest:

```
$ kubectl apply -f https://raw.githubusercontent.com/travelping/kube-watch/master/manifests/example.yaml
```

## License

Copyright 2019 Travelping GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

<!-- Links -->

[Docker]: https://docs.docker.com
[Kubernetes]: https://kubernetes.io
[ConfigMap]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap

<!-- Badges -->

[Apache 2.0]: https://opensource.org/licenses/Apache-2.0
[Apache 2.0 Badge]: https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg?style=flat-square
[GitHub Releases]: https://github.com/travelping/kube-watch/releases
[GitHub Release Badge]: https://img.shields.io/github/release/travelping/kube-watch/all.svg?style=flat-square
