#!/bin/bash

# 🎯 Advanced Dotfiles Manager - Profesyonel seviye dotfiles yönetimi
# Yazar: Claude AI - Senin script'inden ilham alarak yazıldı 😎

set -euo pipefail  # Hata durumunda dur, undefined değişkenleri yakala

# 🎨 Renkli çıktı için
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# 📁 Dizin yapılandırması
readonly DOTFILES_DIR="${HOME}/dotfiles"
readonly CONFIG_DIR="${HOME}/.config"
readonly BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
readonly LOG_FILE="${HOME}/.dotfiles_manager.log"

# 🔧 Özellikler
INTERACTIVE=true
BACKUP_ENABLED=true
VERBOSE=false
DRY_RUN=false
FORCE=false

# 📊 İstatistikler
PROCESSED_APPS=0
CONFLICTS_RESOLVED=0
SYMLINKS_CREATED=0
ERRORS=0

# 🎯 Kullanım bilgisi
usage() {
    cat << EOF
${CYAN}🔧 Advanced Dotfiles Manager${NC}
${WHITE}Kullanım:${NC} $0 [SEÇENEKLER]

${YELLOW}SEÇENEKLER:${NC}
  -h, --help           Bu yardım mesajını göster
  -v, --verbose        Detaylı çıktı
  -q, --quiet          Sessiz mod (etkileşimsiz)
  -n, --dry-run        Sadece göster, hiçbir şey yapma
  -f, --force          Onay istemeden devam et
  -b, --backup PATH    Yedek dizini (varsayılan: ${BACKUP_DIR})
  --no-backup          Yedek alma
  --check              Mevcut dotfiles durumunu kontrol et
  --restore            Son yedekten geri yükle

${GREEN}ÖRNEKLER:${NC}
  $0                   # Normal çalıştırma
  $0 -v                # Detaylı çıktı ile
  $0 -n                # Sadece ne yapacağını göster
  $0 --check           # Mevcut durumu kontrol et
  $0 --restore         # Geri yükle

${PURPLE}💡 Bu script senin yazdığın script'in gelişmiş versiyonu!${NC}
EOF
}

# 🎨 Fancy log fonksiyonu
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}✅ ${message}${NC}" ;;
        "WARN")  echo -e "${YELLOW}⚠️  ${message}${NC}" ;;
        "ERROR") echo -e "${RED}❌ ${message}${NC}" ;;
        "DEBUG") [[ "$VERBOSE" == true ]] && echo -e "${BLUE}🔍 ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}🎉 ${message}${NC}" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 🔍 Sistem kontrolü
check_dependencies() {
    log "DEBUG" "Sistem bağımlılıkları kontrol ediliyor..."
    
    local deps=("stow" "git" "find" "ln")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Eksik bağımlılıklar: ${missing[*]}"
        log "INFO" "Kurulum: sudo apt install ${missing[*]} # Ubuntu/Debian için"
        exit 1
    fi
    
    log "DEBUG" "Tüm bağımlılıklar mevcut ✓"
}

# 📊 Dotfiles durumunu kontrol et
check_status() {
    log "INFO" "Dotfiles durumu kontrol ediliyor..."
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log "ERROR" "Dotfiles dizini bulunamadı: $DOTFILES_DIR"
        exit 1
    fi
    
    cd "$DOTFILES_DIR"
    
    # Git durumu
    if [[ -d ".git" ]]; then
        local git_status=$(git status --porcelain 2>/dev/null || echo "")
        if [[ -n "$git_status" ]]; then
            log "WARN" "Git repository'de uncommitted değişiklikler var"
            [[ "$VERBOSE" == true ]] && git status --short
        fi
        
        local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
        if [[ "$behind" -gt 0 ]]; then
            log "WARN" "Local branch $behind commit geride, git pull yapmanız önerilir"
        fi
    fi
    
    # Mevcut symlink'leri kontrol et
    local broken_links=0
    while IFS= read -r -d '' link; do
        if [[ ! -e "$link" ]]; then
            log "WARN" "Kırık symlink: $link"
            ((broken_links++))
        fi
    done < <(find "$CONFIG_DIR" -type l -print0 2>/dev/null || true)
    
    if [[ "$broken_links" -gt 0 ]]; then
        log "WARN" "$broken_links adet kırık symlink bulundu"
    fi
    
    log "SUCCESS" "Durum kontrolü tamamlandı"
}

# 💾 Güvenli yedekleme
backup_file() {
    local file="$1"
    local backup_path="${BACKUP_DIR}${file#$HOME}"
    
    if [[ "$BACKUP_ENABLED" == false ]]; then
        return 0
    fi
    
    if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
        log "DEBUG" "Yedekleniyor: $file → $backup_path"
        mkdir -p "$(dirname "$backup_path")"
        cp -r "$file" "$backup_path"
        return 0
    fi
    return 1
}

# 🔄 Akıllı çakışma çözümü
resolve_conflict() {
    local src="$1"
    local dest="$2"
    local app="$3"
    
    if [[ ! -e "$dest" ]]; then
        return 0  # Çakışma yok
    fi
    
    if [[ -L "$dest" ]]; then
        local current_target=$(readlink "$dest")
        if [[ "$current_target" == "$src" ]]; then
            log "DEBUG" "Symlink zaten doğru: $dest"
            return 0
        else
            log "WARN" "Yanlış symlink: $dest → $current_target"
        fi
    fi
    
    ((CONFLICTS_RESOLVED++))
    
    if [[ "$INTERACTIVE" == true ]] && [[ "$FORCE" == false ]]; then
        echo -e "\n${YELLOW}🤔 Çakışma bulundu:${NC}"
        echo -e "   Kaynak: ${CYAN}$src${NC}"
        echo -e "   Hedef:  ${PURPLE}$dest${NC}"
        echo -e "   Uygulama: ${WHITE}$app${NC}"
        
        if [[ -f "$dest" ]]; then
            echo -e "\n${BLUE}📄 Mevcut dosya içeriği (son 5 satır):${NC}"
            tail -n 5 "$dest" 2>/dev/null || echo "   [Okunamıyor]"
        fi
        
        echo -e "\n${YELLOW}Ne yapmak istiyorsun?${NC}"
        echo "  1) Yedekle ve değiştir (önerilen)"
        echo "  2) Atla"
        echo "  3) Zorla değiştir (yedeksiz)"
        echo "  4) Diff'ini göster"
        echo "  5) Çık"
        
        while true; do
            read -p "Seçenek (1-5): " choice
            case "$choice" in
                1) backup_file "$dest" && rm -rf "$dest"; return 0 ;;
                2) return 1 ;;
                3) rm -rf "$dest"; return 0 ;;
                4) 
                    if command -v diff &> /dev/null; then
                        diff -u "$dest" "$src" || true
                    else
                        echo "diff komutu bulunamadı"
                    fi
                    ;;
                5) log "INFO" "Kullanıcı tarafından iptal edildi"; exit 0 ;;
                *) echo "Geçersiz seçenek, tekrar deneyin" ;;
            esac
        done
    else
        # Otomatik mod
        if backup_file "$dest"; then
            log "INFO" "Çakışma çözüldü: $dest yedeklendi"
        fi
        rm -rf "$dest"
        return 0
    fi
}

# 🔗 Symlink oluşturma
create_symlink() {
    local src="$1"
    local dest="$2"
    
    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY-RUN] Symlink oluşturulacak: $dest → $src"
        return 0
    fi
    
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    ((SYMLINKS_CREATED++))
    log "DEBUG" "Symlink oluşturuldu: $dest → $src"
}

# 🚀 Ana işlem fonksiyonu  
process_app() {
    local app="$1"
    local app_dir="$DOTFILES_DIR/$app"
    local config_src="$app_dir/.config"
    
    if [[ ! -d "$config_src" ]]; then
        log "DEBUG" "Atlanıyor: $app (.config dizini yok)"
        return 0
    fi
    
    log "INFO" "İşleniyor: ${CYAN}$app${NC}"
    ((PROCESSED_APPS++))
    
    # Dosyaları bul ve işle
    while IFS= read -r -d '' file; do
        local rel_path="${file#$config_src/}"
        local dest_path="$CONFIG_DIR/$rel_path"
        
        if resolve_conflict "$file" "$dest_path" "$app"; then
            create_symlink "$file" "$dest_path"
        else
            log "WARN" "Atlandı: $rel_path"
        fi
    done < <(find "$config_src" -type f -print0)
    
    # Stow ile bağlantıları oluştur
    if [[ "$DRY_RUN" == false ]]; then
        log "DEBUG" "Stow çalıştırılıyor: $app"
        if stow "$app" 2>/dev/null; then
            log "DEBUG" "Stow başarılı: $app"
        else
            log "WARN" "Stow başarısız: $app (muhtemelen zaten yapılmış)"
        fi
    fi
}

# 📈 İstatistikleri göster
show_stats() {
    echo -e "\n${WHITE}📊 İşlem İstatistikleri:${NC}"
    echo -e "   ${GREEN}İşlenen uygulamalar:${NC} $PROCESSED_APPS"
    echo -e "   ${YELLOW}Çözülen çakışmalar:${NC} $CONFLICTS_RESOLVED"
    echo -e "   ${BLUE}Oluşturulan symlink'ler:${NC} $SYMLINKS_CREATED"
    echo -e "   ${RED}Hatalar:${NC} $ERRORS"
    
    if [[ "$BACKUP_ENABLED" == true ]] && [[ -d "$BACKUP_DIR" ]]; then
        echo -e "   ${PURPLE}Yedek dizini:${NC} $BACKUP_DIR"
    fi
    
    echo -e "   ${CYAN}Log dosyası:${NC} $LOG_FILE"
}

# 🔄 Geri yükleme
restore_backup() {
    local backup_dirs=($(ls -d "${HOME}/.dotfiles_backup_"* 2>/dev/null | sort -r))
    
    if [[ ${#backup_dirs[@]} -eq 0 ]]; then
        log "ERROR" "Hiç yedek bulunamadı"
        exit 1
    fi
    
    echo -e "${YELLOW}📦 Mevcut yedekler:${NC}"
    for i in "${!backup_dirs[@]}"; do
        echo "  $((i+1))) $(basename "${backup_dirs[$i]}")"
    done
    
    read -p "Hangi yedekten geri yüklensin? (1-${#backup_dirs[@]}): " choice
    
    if [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#backup_dirs[@]} ]]; then
        local selected_backup="${backup_dirs[$((choice-1))]}"
        log "INFO" "Geri yükleniyor: $selected_backup"
        
        # Mevcut symlink'leri temizle
        find "$CONFIG_DIR" -type l -delete 2>/dev/null || true
        
        # Yedekten geri yükle
        cp -r "$selected_backup"/. "$HOME/"
        
        log "SUCCESS" "Geri yükleme tamamlandı!"
    else
        log "ERROR" "Geçersiz seçim"
        exit 1
    fi
}

# 🎬 Ana program
main() {
    # Parametreleri işle
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)      usage; exit 0 ;;
            -v|--verbose)   VERBOSE=true ;;
            -q|--quiet)     INTERACTIVE=false ;;
            -n|--dry-run)   DRY_RUN=true ;;
            -f|--force)     FORCE=true ;;
            -b|--backup)    BACKUP_DIR="$2"; shift ;;
            --no-backup)    BACKUP_ENABLED=false ;;
            --check)        check_dependencies; check_status; exit 0 ;;
            --restore)      restore_backup; exit 0 ;;
            *)              log "ERROR" "Bilinmeyen parametre: $1"; usage; exit 1 ;;
        esac
        shift
    done
    
    # Başlangıç mesajı
    echo -e "${PURPLE}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║     🚀 Advanced Dotfiles Manager     ║"
    echo "  ║        Seninkinden daha iyi! 😎      ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    # Sistem kontrolleri
    check_dependencies
    check_status
    
    # Ana dizin kontrolü
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log "ERROR" "Dotfiles dizini bulunamadı: $DOTFILES_DIR"
        exit 1
    fi
    
    cd "$DOTFILES_DIR"
    
    # Yedek dizini oluştur
    if [[ "$BACKUP_ENABLED" == true ]] && [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$BACKUP_DIR"
        log "INFO" "Yedek dizini oluşturuldu: $BACKUP_DIR"
    fi
    
    # Uygulamaları işle
    for app in */; do
        app=${app%/}  # Slash'i kaldır
        [[ -d "$app" ]] || continue
        
        process_app "$app" || ((ERRORS++))
    done
    
    # Sonuçları göster
    show_stats
    
    if [[ "$ERRORS" -eq 0 ]]; then
        log "SUCCESS" "Tüm dotfiles başarıyla işlendi! 🎉"
    else
        log "WARN" "İşlem tamamlandı ancak $ERRORS hata oluştu"
        exit 1
    fi
}

# 🎯 Programı başlat
main "$@"