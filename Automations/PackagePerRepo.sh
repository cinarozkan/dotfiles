#!/bin/bash

declare -A repo_counts

# Repoları al
repos=$(pacman -Sl | cut -d' ' -f1 | sort -u)

# Paket sayılarını al
for repo in $repos; do
    count=$(pacman -Sl "$repo" 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        repo_counts["$repo"]=$count
    fi
done

# AUR sayısı
aur_count=$(pacman -Qqm 2>/dev/null | wc -l)

# Toplam paket sayısı
total_count=0
for c in "${repo_counts[@]}"; do
    ((total_count+=c))
done
((total_count+=aur_count))

# Renkler
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

# Reposu sayıya göre sırala
sorted_repos=$(for k in "${!repo_counts[@]}"; do
    echo "$k ${repo_counts[$k]}"
done | sort -k2 -nr)

# Bar uzunluğu
bar_length=50

# Bar fonksiyonu
print_bar() {
    local count=$1
    local total=$2

    # Yüzdeyi virgüllü hesapla
    local percent=$(awk "BEGIN { printf \"%.2f\", ($count / $total) * 100 }")

    # Bar uzunluğu, yüzdeye göre
    local length=$(awk "BEGIN { l = int(($count / $total) * $bar_length); if (l < 1 && $count > 0) l = 1; print l }")

    # Bar çizimi
    local bar=$(printf '#%.0s' $(seq 1 $length))

    # Yüzdeyi 2 hane olarak ekle
    printf "%-${bar_length}s %6s%%" "$bar" "$percent"
}

# Başlık
echo -e "${CYAN}Arch Linux Repo Paket Dağılımı${RESET}"
echo -e "Toplam Paket Sayısı: ${YELLOW}$total_count${RESET}"
echo "-------------------------------------------"

# Verileri yazdır
while read -r line; do
    repo=$(echo "$line" | awk '{print $1}')
    count=$(echo "$line" | awk '{print $2}')
    bar=$(print_bar "$count" "$total_count")
    printf "%-20s : %5d paket | ${GREEN}%s${RESET}\n" "$repo" "$count" "$bar"
done <<< "$sorted_repos"

# AUR için
aur_bar=$(print_bar "$aur_count" "$total_count")
printf "%-20s : %5d paket | ${GREEN}%s${RESET}\n" "AUR" "$aur_count" "$aur_bar"
