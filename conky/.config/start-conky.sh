#!/bin/bash

# Eğer çalışan eski conky varsa kapatır, hata mesajını gizler
killall conky 2>/dev/null
sleep 2

# Ana conky dizini
PARENT_DIR="$HOME/.config/conky"

# Sadece ~/.config/conky/ içindeki KLASÖRLERİ döngüye alır
for folder in "$PARENT_DIR"/*/; do
    # Klasörün varlığını kontrol eder (boşsa hata vermemesi için)
    [ -d "$folder" ] || continue
    
    # Klasörün içindeki .conf uzantılı dosyaları bulur ve çalıştırır
    for config_file in "$folder"*.conf; do
        # Dosya gerçekten mevcutsa ve okunabiliyorsa çalıştırır
        if [ -f "$config_file" ]; then
            echo "Klasör: $(basename "$folder") -> Başlatılıyor: $(basename "$config_file")"
            conky -c "$config_file" &
        fi
    done
done
