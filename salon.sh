#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

LIST_SERVICES() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # Ambil daftar layanan dari database
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  
  # Tampilkan daftar layanan dengan format: #) <service>
  echo "$SERVICES" | while IFS="|" read SERVICE_ID NAME
  do
    echo "$SERVICE_ID) $NAME"
  done

  # Prompt pertama: Pilih layanan
  read SERVICE_ID_SELECTED

  # Cek apakah layanan tersedia
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

  # Jika tidak ditemukan, tampilkan daftar lagi
  if [[ -z $SERVICE_NAME ]]
  then
    LIST_SERVICES "I could not find that service. What would you like today?"
  else
    # Jika ditemukan, lanjut ke input data pelanggan
    PROCESS_APPOINTMENT
  fi
}

PROCESS_APPOINTMENT() {
  # Masukkan nomor telepon
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Cari nama pelanggan berdasarkan nomor telepon
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # Jika pelanggan belum ada (nomor tidak terdaftar)
  if [[ -z $CUSTOMER_NAME ]]
  then
    # Minta nama pelanggan baru
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    
    # Masukkan data pelanggan baru ke tabel customers
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
  fi

  # Ambil customer_id untuk proses booking
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # Minta waktu layanan
  # Kita gunakan sed untuk membersihkan spasi dari variabel agar output rapi
  CLEAN_SERVICE_NAME=$(echo $SERVICE_NAME | sed 's/ //g')
  CLEAN_CUSTOMER_NAME=$(echo $CUSTOMER_NAME | sed 's/ //g')

  echo -e "\nWhat time would you like your $CLEAN_SERVICE_NAME, $CLEAN_CUSTOMER_NAME?"
  read SERVICE_TIME

  # Masukkan janji temu ke tabel appointments
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

  # Output pesan sukses akhir
  echo -e "\nI have put you down for a $CLEAN_SERVICE_NAME at $SERVICE_TIME, $CLEAN_CUSTOMER_NAME."
}

LIST_SERVICES