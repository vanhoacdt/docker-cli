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
        find "$HOME/docker" -maxdepth 2 \( -name "docker-compose.yml" -o -name "compose.yml" \) -printf '%h\n' 2>/dev/null | xargs -r -n1 basename
    fi
}

_dps_completion() {
    local cur prev words cword
    _init_completion || return

    local opts="-a -u -r -k -m -n -t -e -s -w -x -d -p -i -c -o -l -f -h --help"

    if [[ $cword -eq 1 ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        else
            local running projs
            running=$(docker ps --format '{{.Names}}' 2>/dev/null)
            projs=$(_dps_list_projects)
            COMPREPLY=( $(compgen -W "$opts $running $projs" -- "$cur") )
            [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
        fi
        return 0
    fi

    # Gợi ý service của dự án khi đã nhập đường dẫn / tên dự án ở vị trí tham số trước đó
    if [[ $cword -ge 3 ]]; then
        case "${words[1]}" in
            -u|--up|-r|--restart|-k|--stop|-m|--rm|-l|--logs|-f|--follow|-c|--inspect|-t|--top|-x|--exec|-w|--watch)
                local svcs
                svcs=$(_dps_find_compose_svcs "${words[2]}")
                if [[ -n "$svcs" ]]; then
                    local extra=""
                    [[ "${words[1]}" == "-u" || "${words[1]}" == "--up" ]] && extra="--force-recreate --build --no-deps"
                    COMPREPLY=( $(compgen -W "$svcs $extra" -- "$cur") )
                    return 0
                fi
                ;;
        esac
    fi

    case "$prev" in
        -u|--up)
            local svcs=""
            if [[ -f "docker-compose.yml" || -f "docker-compose.yaml" || -f "compose.yml" || -f "compose.yaml" ]]; then
                svcs=$(docker compose config --services 2>/dev/null)
            else
                svcs=$(_dps_list_projects)
            fi
            COMPREPLY=( $(compgen -W "$svcs" -- "$cur") )
            [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
            return 0
            ;;
        -r|--restart|-k|--stop|-m|--rm|-t|--top|-x|--exec|-l|--logs|-f|--follow|-w|--watch)
            local running projs
            running=$(docker ps --format '{{.Names}}' 2>/dev/null)
            projs=$(_dps_list_projects)
            COMPREPLY=( $(compgen -W "$running $projs" -- "$cur") )
            [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
            return 0
            ;;
        -c|--inspect|-a|-s|-d|-p|-e)
            local all_c projs
            all_c=$(docker ps -a --format '{{.Names}}' 2>/dev/null)
            projs=$(_dps_list_projects)
            COMPREPLY=( $(compgen -W "$all_c $projs" -- "$cur") )
            [[ "$cur" == */* || "$cur" == ~* || "$cur" == .* ]] && _filedir
            return 0
            ;;
        -n|--network)
            local nets
            nets=$(docker network ls --format '{{.Name}}' 2>/dev/null)
            COMPREPLY=( $(compgen -W "$nets" -- "$cur") )
            return 0
            ;;
        -i|--images)
            local imgs
            imgs=$(docker images --format '{{.Repository}}' 2>/dev/null | grep -v '^<none>$')
            COMPREPLY=( $(compgen -W "$imgs" -- "$cur") )
            return 0
            ;;
    esac
}
complete -F _dps_completion dps
