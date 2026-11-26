# Ejercicio ec2-ebs · Crear, montar y restaurar EBS

Terraform crea una EC2 (Amazon Linux 2023) y un volumen de datos **gp3** en la misma AZ. Dentro de la instancia se formatea, se monta, se hace persistente con `/etc/fstab` y se comprueba tras detener/iniciar. Al final se crea un snapshot y se restaura en un **volumen independiente**.

```text
us-east-1a
┌──────────────────────── EC2 ec2-ebs-lab (t3.micro, AL2023) ───────────────────────┐
│  /dev/nvme0n1  raíz 8 GiB                                                          │
│  /dev/sdf → /dev/nvme1n1  ec2-ebs-data (gp3 1 GiB)  → XFS montado en /data        │
│  /dev/sdg → /dev/nvme2n1  ec2-ebs-restored (fase 2) → montado en /restore         │
└───────────────────────────────────────────────────────────────────────────────────┘
                 ec2-ebs-data ──snapshot──► ec2-ebs-data-snapshot ──► ec2-ebs-restored
```

| Archivo | Contenido |
| --- | --- |
| `main.tf` | AMI, subred, Security Group (SSH para Instance Connect), EC2, volumen gp3 y su attachment |
| `snapshot.tf` | Fase 2: snapshot y volumen restaurado (solo con `create_snapshot = true`) |
| `variables.tf` / `outputs.tf` | Región, AZ, tamaño; IDs y comando para conectarse |

## 1. Crear los recursos (pasos 1 y 2)

```bash
aws login --region us-east-1                      # sesión temporal, sin access keys
eval "$(aws configure export-credentials --format env)"
terraform init
terraform apply
```

## 2. Dentro de la EC2 (pasos 2 a 4)

```bash
$(terraform output -raw connect_command)
```

```bash
# Paso 2: identificar el disco nuevo. /dev/sdf es un enlace al dispositivo NVMe real.
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,SERIAL
DEV=$(readlink -f /dev/sdf); echo $DEV
sudo file -s $DEV                 # "data" = vacío, sin sistema de archivos

# Paso 3: formatear SOLO el volumen nuevo, montar y crear un archivo
sudo mkfs -t xfs $DEV
sudo mkdir -p /data && sudo mount $DEV /data
echo "Hola EBS $(date -u)" | sudo tee /data/prueba.txt
df -h /data

# Paso 4: montaje persistente con UUID (nofail: la EC2 arranca aunque falte el disco)
UUID=$(sudo blkid -s UUID -o value $DEV)
sudo cp /etc/fstab /etc/fstab.bak
echo "UUID=$UUID  /data  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
sudo umount /data && sudo mount -a && df -h /data   # si monta, fstab es correcto
exit
```

## 3. Detener e iniciar la EC2 (paso 5)

```bash
ID=$(terraform output -raw instance_id)
aws ec2 stop-instances --instance-ids $ID && aws ec2 wait instance-stopped --instance-ids $ID
aws ec2 start-instances --instance-ids $ID && aws ec2 wait instance-running --instance-ids $ID
sleep 30 && $(terraform output -raw connect_command)
```

```bash
df -h /data && cat /data/prueba.txt   # el volumen se montó solo y los datos siguen
exit
```

## 4. Snapshot y restauración en un volumen independiente

```bash
terraform apply -var create_snapshot=true
$(terraform output -raw connect_command)
```

```bash
RDEV=$(readlink -f /dev/sdg)
lsblk -f                                   # los dos discos tienen el MISMO UUID (copia exacta)
sudo mkdir -p /restore && sudo mount -o nouuid $RDEV /restore
cat /restore/prueba.txt                    # mismos datos, en otro volumen
```

XFS no permite montar dos sistemas con el mismo UUID: `nouuid` lo permite para esta comprobación. El volumen restaurado no se añade a `/etc/fstab`.

## Limpieza

```bash
terraform destroy -var create_snapshot=true
```
