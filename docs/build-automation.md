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
