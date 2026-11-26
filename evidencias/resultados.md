# Resultados del ejercicio ec2-ebs

Ejecutado el 2026-11-26 en `us-east-1a`.

## Paso 1 · Recursos creados con Terraform

```text
aws_security_group.ssh: Creation complete after 2s [id=sg-01cce637db1950437]
aws_instance.lab: Creation complete after 17s [id=i-09695c0778a67b219]
aws_ebs_volume.data: Creation complete after 11s [id=vol-0eef8e1add6d0bfec]
aws_volume_attachment.data: Creation complete after 21s [id=vai-3375067783]
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

EC2 `t3.micro` Amazon Linux 2023 y volumen gp3 de 1 GiB, ambos en `us-east-1a`.

## Paso 2 · Identificar el dispositivo vacío

```text
NAME          SIZE TYPE FSTYPE MOUNTPOINTS SERIAL
nvme0n1         8G disk                    vol078b009478b177ac5
├─nvme0n1p1     8G part xfs    /
nvme1n1         1G disk                    vol0eef8e1add6d0bfec
Disco de datos (/dev/sdf) -> /dev/nvme1n1
/dev/nvme1n1: data
```

El SERIAL coincide con el ID del volumen de Terraform y `file -s` responde `data`: está vacío.

## Paso 3 · Formatear, montar y crear un archivo

```text
Hola EBS Thu Nov 26 01:57:26 UTC 2026
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme1n1    960M   40M  921M   5% /data
```

## Paso 4 · /etc/fstab con UUID

```text
UUID=bb720792-4092-4ca4-a824-2180d13e7065  /data  xfs  defaults,nofail  0  2
mount -a OK
```

## Paso 5 · Detener / iniciar y verificar

```text
stopping → stopped → pending → running   (nueva IP pública)
== Tras detener/iniciar: up 0 minutes
/dev/nvme1n1    960M   40M  921M   5% /data
Hola EBS Thu Nov 26 01:57:26 UTC 2026
```

El volumen se montó solo gracias a `fstab` y los datos se conservaron.

## Restauración del snapshot en un volumen independiente

```text
aws_ebs_snapshot.data[0]: Creation complete after 36s [id=snap-0638550715b43fb92]
aws_ebs_volume.restored[0]: Creation complete after 11s [id=vol-04a0c653f1e5af403]
aws_volume_attachment.restored[0]: Creation complete after 20s [id=vai-1223048363]
```

```text
NAME    SIZE FSTYPE UUID                                 MOUNTPOINTS SERIAL
nvme1n1   1G xfs    bb720792-4092-4ca4-a824-2180d13e7065 /data       vol0eef8e1add6d0bfec
nvme2n1   1G xfs    bb720792-4092-4ca4-a824-2180d13e7065             vol04a0c653f1e5af403

/restore/prueba.txt (restaurado): Hola EBS Thu Nov 26 01:57:26 UTC 2026

Escribo solo en el original:
original:   Hola EBS ... + "cambio posterior al snapshot"
restaurado: Hola EBS ...            (no cambia: es un volumen independiente)
```

El volumen restaurado es una copia exacta (mismo UUID de XFS, por eso se monta con `-o nouuid`), pero es un disco distinto: los cambios en el original no le afectan.
