# Автоматизация сборки

## Автоинкремент Build Number при Archive

Для автоматического увеличения `CFBundleVersion` (build number) при Archive-сборках используется `agvtool` в Pre-action.

### Почему не Build Phase?

`agvtool` модифицирует `project.pbxproj`. Если запустить его в Build Phase, Xcode увидит изменение проекта и отменит сборку ("Build Cancelled").

### Настройка

1. **Build Settings → Versioning System** → "Apple Generic"
2. **Build Settings → Current Project Version** → начальный номер (например, `1`)
3. **Product → Scheme → Edit Scheme → Archive → Pre-actions**:
   - "+" → "New Run Script Action"
   - "Provide build settings from" → выбрать target
   - Скрипт:
     ```bash
     cd "$PROJECT_DIR"
     agvtool next-version -all
     ```

### Примечание

Переменная `$INFOPLIST_FILE` может быть пустой в проектах с автогенерируемым Info.plist (опция "Generate Info.plist File" в Build Settings).

## Версионирование

### Два параметра версии

| Параметр | Info.plist ключ | Назначение |
|----------|-----------------|------------|
| `MARKETING_VERSION` | CFBundleShortVersionString | Версия для пользователей (1.0.0) |
| `CURRENT_PROJECT_VERSION` | CFBundleVersion | Build number (сквозной) |

### Build Number — сквозной

Build number **не сбрасывается** при смене marketing version. App Store требует уникальный номер для каждого загруженного билда.

### Изменение версии

```bash
# Установить marketing version (SemVer)
agvtool new-marketing-version 1.1.0

# Увеличить build number
agvtool next-version -all
```

Или вручную: Target → General → Identity → поля Version и Build.
