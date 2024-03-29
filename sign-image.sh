#!/bin/bash

# Установите URL архива
ARCHIVE_URL="https://sourceforge.net/projects/nippongsi/files/MIUI%20-%20MIUI-EU-[14.0.6]-sunstone-b%20-%20K8BOY6OAT7/MIUI-EU-[14.0.6]-sunstone-b-AB-13-20230724-NipponGSI.img.gz"

# Установите пути к ключам
PRIVATE_KEY_PATH="sign-avb/private_key_rsa2048.pem"
PUBLIC_KEY_METADATA_PATH="sign-avb/public_key_metadata.bin"

# Загрузите архив
wget "$ARCHIVE_URL" -O temp_archive

# Определите тип архива и разархивируйте
mkdir -p unpacked
if [[ $ARCHIVE_URL == *.zip ]]; then
  unzip -d unpacked temp_archive
elif [[ $ARCHIVE_URL == *.gz ]]; then
  tar -xzf temp_archive -C unpacked
else
  echo "Unsupported archive format"
  rm temp_archive
  exit 1
fi

# Найдите файл с расширением .img в распакованной директории
IMG_PATH=$(find unpacked -type f -name "*.img")
if [[ -z "$IMG_PATH" ]]; then
  echo "No .img file found in archive"
  rm temp_archive
  rm -r unpacked
  exit 1
fi

# Получите размер раздела в байтах
PARTITION_SIZE=$(du -b "$IMG_PATH" | cut -f1)

# Подпишите .img используя avbtool
avbtool add_hash_footer --image "$IMG_PATH" --partition_size "$PARTITION_SIZE" 
   --partition_name system --key "$PRIVATE_KEY_PATH" --algorithm SHA256_RSA2048 
   --public_key_metadata "$PUBLIC_KEY_METADATA_PATH" --output "signed_$(basename $IMG_PATH)"

if [[ $? -eq 0 ]]; then
  echo "Image has been successfully signed and is located at signed_$(basename $IMG_PATH)"
else
  echo "There was an error signing the image."
fi

# Очистите временные файлы
rm temp_archive
rm -r unpacked

exit 0
