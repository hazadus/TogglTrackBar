# `just` без параметров выводит список доступных команд
default:
    @just --list

# Сгенерировать сообщение коммита (см. https://github.com/hazadus/gh-commitmsg)
commitmsg:
    gh commitmsg --examples --language russian

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

swift_format := "xcrun swift-format"
swift_files_paths := "./TogglTrackBar/"

# Применить форматирование
format:
    {{swift_format}} format --recursive --in-place {{swift_files_paths}}

# Проверить форматирование (для CI)
format-check:
    {{swift_format}} lint --recursive {{swift_files_paths}}

swiftlint := "swiftlint"

# Линтинг
lint:
    {{swiftlint}} lint --config .swiftlint.yml {{swift_files_paths}}

# Линтинг с автоисправлением
lint-fix:
    {{swiftlint}} --fix --config .swiftlint.yml {{swift_files_paths}}

# Строгая проверка для CI
lint-check:
    {{swiftlint}} lint --strict --config .swiftlint.yml {{swift_files_paths}}

# Установить pre-commit hook
install-hooks:
    mkdir -p .git/hooks
    # NB: путь ../../Scripts/pre-commit относительно .git/hooks/
    ln -s ../../Scripts/pre-commit .git/hooks/pre-commi
    chmod +x ./Scripts/pre-commit
