_dps_running_containers() {
    docker ps --filter "status=running" --filter "status=restarting" --format "{{.Names}}" 2>/dev/null
}

_dps_all_containers() {
    docker ps -a --format "{{.Names}}" 2>/dev/null
}

_dps_find_compose_svcs() {
    local target="${1/#\~/$HOME}"
    local cfile=""
    if [[ -f "$target" ]]; then
        cfile="$target"
    elif [[ -d "$target" ]]; then
        for cf in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
            [[ -f "$target/$cf" ]] && { cfile="$target/$cf"; break; }
        done
    elif [[ -d "$HOME/docker/$target" ]]; then
        for cf in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
            [[ -f "$HOME/docker/$target/$cf" ]] && { cfile="$HOME/docker/$target/$cf"; break; }
        done
    fi
    if [[ -n "$cfile" ]]; then
        docker compose -f "$cfile" config --services 2>/dev/null
    fi
}

_dps_list_projects() {
    if [[ -d "$HOME/docker" ]]; then
        find "$HOME/docker" -maxdepth 2 \( -name "docker-compose.yml" -o -name "compose.yml" \) -printf "%h\n" 2>/dev/null | xargs -r -n1 basename
    fi
}

# Lọc bỏ các đối số đã xuất hiện trên dòng lệnh (từ words[2] tới words[cword-1])
_dps_filter_used() {
    local candidates="$1"
    local item w skip
    for item in $candidates; do
        skip=0
        for ((i=2; i<cword; i++)); do
            w="${words[i]}"
            if [[ "$item" == "$w" ]]; then
                skip=1
                break
            fi
        done
        [[ $skip -eq 0 ]] && echo "$item"
    done
}

_dps_completion() {
    local cur prev words cword
    _init_completion || return

    local opts="-a -u -r -k -m -n -t -e -s -w -x -d -p -i -c -o -l -f -h --help"

    if [[ $cword -eq 1 ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        else
            local running
            running=$(_dps_running_containers)
            COMPREPLY=( $(compgen -W "$opts $running" -- "$cur") )
            [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
        fi
        return 0
    fi

    # Gợi ý tiếp các mục tiêu chưa được chọn từ đối số thứ 2 trở đi ($cword >= 3)
    if [[ $cword -ge 3 ]]; then
        case "${words[1]}" in
            -k|--stop|-t|--top|-f|--follow|-w|--watch|-p)
                local svcs=""
                [[ $cword -eq 3 ]] && svcs=$(_dps_find_compose_svcs "${words[2]}")
                local running filtered
                running=$(_dps_running_containers)
                filtered=$(_dps_filter_used "$svcs $running")
                COMPREPLY=( $(compgen -W "$filtered" -- "$cur") )
                [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
                return 0
                ;;
            -r|--restart|-m|--rm|-c|--inspect|-l|--logs|-a|-s|-d)
                local svcs=""
                [[ $cword -eq 3 ]] && svcs=$(_dps_find_compose_svcs "${words[2]}")
                local all_c filtered
                all_c=$(_dps_all_containers)
                filtered=$(_dps_filter_used "$svcs $all_c")
                COMPREPLY=( $(compgen -W "$filtered" -- "$cur") )
                [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
                return 0
                ;;
            -u|--up)
                local svcs projs all_c filtered
                svcs=$(_dps_find_compose_svcs "${words[2]}")
                if [[ -n "$svcs" ]]; then
                    filtered=$(_dps_filter_used "$svcs --force-recreate --build --no-deps")
                    COMPREPLY=( $(compgen -W "$filtered" -- "$cur") )
                    return 0
                fi
                projs=$(_dps_list_projects)
                all_c=$(_dps_all_containers)
                filtered=$(_dps_filter_used "$projs $all_c")
                COMPREPLY=( $(compgen -W "$filtered" -- "$cur") )
                [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
                return 0
                ;;
            -x|--exec)
                local svcs filtered
                svcs=$(_dps_find_compose_svcs "${words[2]}")
                if [[ -n "$svcs" ]]; then
                    filtered=$(_dps_filter_used "$svcs")
                    COMPREPLY=( $(compgen -W "$filtered" -- "$cur") )
                    return 0
                fi
                ;;
        esac
    fi

    case "$prev" in
        -u|--up)
            local svcs="" projs="" all_c=""
            if [[ -f "docker-compose.yml" || -f "docker-compose.yaml" || -f "compose.yml" || -f "compose.yaml" ]]; then
                svcs=$(docker compose config --services 2>/dev/null)
            fi
            projs=$(_dps_list_projects)
            all_c=$(_dps_all_containers)
            COMPREPLY=( $(compgen -W "$svcs $projs $all_c" -- "$cur") )
            [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
            return 0
            ;;
        -k|--stop|-t|--top|-x|--exec|-f|--follow|-w|--watch|-p)
            local running
            running=$(_dps_running_containers)
            COMPREPLY=( $(compgen -W "$running" -- "$cur") )
            [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
            return 0
            ;;
        -r|--restart|-m|--rm|-c|--inspect|-l|--logs|-a|-s|-d|-e)
            local all_c
            all_c=$(_dps_all_containers)
            COMPREPLY=( $(compgen -W "$all_c" -- "$cur") )
            [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
            return 0
            ;;
        -n|--network)
            local nets
            nets=$(docker network ls --format "{{.Name}}" 2>/dev/null)
            COMPREPLY=( $(compgen -W "$nets" -- "$cur") )
            return 0
            ;;
        -i|--images)
            local imgs
            imgs=$(docker images --format "{{.Repository}}" 2>/dev/null | grep -v "^<none>$")
            COMPREPLY=( $(compgen -W "$imgs" -- "$cur") )
            return 0
            ;;
    esac
}
complete -F _dps_completion dps
