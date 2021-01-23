# docker-container-security-lp

## Generate signing keys

```shell
docker trust key generate den1ska --dir ~/.docker/trust
docker trust signer add --key ~/.docker/trust/den1ska.pub den1ska den1ska/hugo-builder

```
