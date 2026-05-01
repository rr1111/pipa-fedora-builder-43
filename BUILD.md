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
- To build the minimal Desktop images:
```
docker run --privileged --rm -v "$(pwd)"/images:/build/images -v "/dev:/dev" pipa-fedora-builder <desktop-arg>
```
replace ```<desktop-arg>``` with the flavor of your choice:
```tty```, ```gnome```, ```plasma```, ```plasma-mobile```

Remove ```-rm``` if you want to keep the container after running 

If you dont pass a desktop arg to the container or pass an invalid one, it will default to ```plasma```!

[Installation guide](./INSTALL.md)

### Building custom images
- add your packages in mkosi.profiles/custom.conf
- or use a group like ```@cosmic-desktop-environment```
- pass ```custom``` as desktop argument
- see what happens, if all packages properly enable their services, it should work

### Building Notes

- takes ~20 minutes on my mid end laptop, so be patient when building
- ```qemu-user-static``` is also needed if youre building the image on a ```non-aarch64``` system  
