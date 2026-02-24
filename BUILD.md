# Building images

### Clone into this repo

```
git clone https://github.com/rr1111/pipa-fedora-builder-43
cd pipa-fedora-builder-43
```

### Build the docker container

```
docker build -t 'pipa-fedora-builder' . 
```

### Run the container with privleges

```
docker run --privileged -v "$(pwd)"/images:/build/images -v "/dev:/dev" pipa-fedora-builder
```

### Building Notes

- takes ~20 minutes on my mid end laptop, so be patient when building
- ```qemu-user-static``` is also needed if youre building the image on a ```non-aarch64``` system  
