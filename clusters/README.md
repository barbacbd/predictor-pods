# Clusters

The Dockerfile is used to create an image that will allow a user to create clusters from their initial dataset. The Dockerfile exposes an executable `/Clusters` to the user.

## Algorithms

The following section describes the algroithms that can be selected for clustering. All listed algorithms are available during configuration. The default algorithm is `K_MEANS`.

### Kmeans / Kmeans1D

The [kmeans](https://scikit-learn.org/stable/modules/generated/sklearn.cluster.KMeans.html) algorithm is applied to multidimensional datasets. When a 1-dimensional dataset has been provided [kmeans1d](https://pypi.org/project/kmeans1d/) is selected. Generally, kmeans is sufficient for clustering because it is an unsupervised form of clustering. Kmeans is _not_ perfect, so the option is also provided to the user to enhance the algorithm a bit more through the `init` parameter. The parameter will ensure that [kmeans++](https://en.wikipedia.org/wiki/K-means%2B%2B) is utilized instead of kmeans.

### X (even spaced) Bins

Evenly dispersed bins aims to solve a problem has is present with kmeans, singletons. Kmeans (the multidimensional algorithm) does not handle outliers in a single dimension. These singletons that are the result of small cluster sizes cause issues with the metrics (above). Evenly spaced bins are generated by taking the `min` and `max` of the entire dataset and creating equal width `k` bins where `k` is the number of clusters.

That is correct, this will also not solve the singleton problem, moving on!

### E (even) Bins

Even bins attempts to place the same number of entries in all bins. This isn't clustering, it's more along the lines of forced clustering. The algorithm is left
in the project, but not used as it is not finding natural breaks (see below) or creating realistic clusters.

### Natural Breaks

The algorithm is specifically called out to aid in clustering 1-dimensional datasets and it can be found [here](https://github.com/mthh/jenkspy).


## Example

Create the image:

```bash
podman build . -t clusters:latest
```

Run the image with the dataset:

```bash
podman run -v ${PWD}/output:/output --privileged clusters:latest /Clusters /output/{file} -a K_MEANS --min_k 2 --max_k 50
```

## Executable Options

The following options are from the example above.

- The `-v` option exposes a directory from the host to the container.
- The `--privileged` option is only required for `podman`.
- The `/output/{file}` option that is provided to `/Clusters` where the file name must exist in the output directory specified in the `-v` option. _This file must be a text file_.
- The min and max k values are the min and max number of clusters respectively to create (each value is a new run of clustering).
- The algorithm, `-a`, can be any of algorithms mentioned above (K_MEANS, X_BINS, E_BINS, NATURAL_BREAKS).

## Output

The output of the container will be a json file with the same name as the original text file in the same directory. The json file will contain the original dataset with a tag `data`. The json file will also contain a tag `clusters`. The data contained in clusters will be in order from `min_k` to `max_k`. A list of lists that contain the cluster number for the subsequent data point from the original dataset when clustered using a value of `k`.

```json
{
    "data": [

    ],
    "clusters": [
        [
	],
    ]
}
```