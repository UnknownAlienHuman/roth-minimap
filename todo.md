# RothMinimap - todo (active)

Цель: стабилизировать миникарту на WoW 12.0.1 и довести `ButtonBag` до рабочего/легкого состояния.

## Stage 1 - P0 ButtonBag crash/useability
- [x] Подтвердить обязательный протокол `_Info` + проверить Blizzard исходники.
- [x] Разобрать текущий `modules/ButtonBag.lua` и найти точки риска.
- [x] Убрать прямую перезапись `Show/Hide/SetPoint/ClearAllPoints` у чужих кнопок.
- [x] Добавить безопасные guarded-вызовы для работы с frame (forbidden/protected-safe).
- [x] Исправить кликабельность кнопок в компактном grid.
- [x] Добавить `Ctrl+RightClick` по кнопке в мешочке -> исключить/вернуть из исключений.

## Stage 2 - P1 Performance
- [x] Убрать лишние сортировки/полные пересборки списка при каждом добавлении.
- [x] Разделить быстрый рескан (Minimap/MinimapCluster) и тяжелый fallback-рескан.
- [x] Снизить лишние таймеры/обходы и table churn в hot-path.

## Stage 3 - P1 Settings consistency + UX
- [ ] Пересобрать раздел настроек (Layout / Skin / Buttons / Advanced) аккуратно по отступам и логике. (частично: cleanup и стабильность внесены, полный редизайн панели не завершен)
- [ ] Проверить, что содержимое панели не пропадает при скролле, и значения сохраняются в `RothMinimapDB`. (кодовые фиксы внесены; runtime-проверка в клиенте нужна)
- [x] Убрать бессмысленные UI-тумблеры (`hideBlizzardArt`, `hideZoomButtons`, `hideNorthTag`) и зафиксировать их как policy.

## Stage 4 - Integration + verify
- [x] Обновить defaults/migration в `RothMinimap.lua` под новую policy и новые поля мешочка.
- [x] Проверить согласованность `Options.lua` <-> `ButtonBag.lua` <-> `RothMinimap.lua`.

## Stage 5 - P0 Minimap bag recovery (current)
- [x] Подтвердить актуальную структуру `MinimapCluster`/`AddonCompartment` в `C:\Tools\WoW_Dev_Tools\wow-ui-source/Blizzard_UI_12.0.1.65867`.
- [x] Усилить сканер кнопок: ограниченная рекурсия + фильтр тяжелых системных поддеревьев.
- [x] Исправить UX-ловушку `showToggle=false` + `stashWhenClosed=true` (не терять доступ к кнопкам).
- [x] Уточнить поведение `pinOnClick` и стабилизировать forwarding кликов прокси.
- [x] Добавить безопасный lifecycle-рескан для поздно появляющихся minimap-кнопок без постоянного OnUpdate.
- [x] Починить черные квадраты в мешке: выбирать icon-текстуру по score, отбрасывать декоративные minimap-текстуры (ring/background/highlight).
- [x] Усилить источник иконок для `LibDBIcon10_*`: прямой `dataObject.icon` + более строгий confidence-threshold (fallback вместо черного квадрата).
- [x] Расширить совместимость обнаружения: глубже обход (`depth=6`) + глобальные паттерны `*MinimapButton*/*MinimapIcon*` для MBB-подобного покрытия.
- [x] Визуальный фикс мешка: убрать уродливый black-square стиль кнопки, вернуть аккуратный minimap-ring вид и не влиять на layout карты.
- [x] Стабилизация отбора иконок: более жесткий threshold + region-name penalties + фильтр plain/decor textures, чтобы убрать черные квадраты.
- [x] Anti-drift: не прятать unknown/non-LibDB кнопки (только контролируемые `LibDBIcon`), чтобы не ломать layout/позицию MinimapCluster.
- [x] Coverage boost: fallback-скан `_G` теперь использует `globalName` как `nameHint` и геометрию рядом с миникартой для кнопок без корректного `GetName()`.
- [x] Anti-freeze: fallback-скан больше не идет по всему `_G` в обычном режиме; теперь force-only + batch-limit + строгий name-filter.
- [x] Anti-garbage: ужесточены фильтры кандидатов (`size`, near-minimap для fallback, icon-score threshold), чтобы убрать мусор/черные текстуры.
- [x] Обновить этот `todo.md` статусами выполнения после внесенных правок.
- [x] Убрать прокси-архитектуру мешка: показывать реальные minimap-кнопки в панели (MBB-style), без рендера иконок через proxy-текстуры.
- [x] Добавить надежный save/restore для кнопок: parent/anchors/size/scale/strata/frameLevel + временный lock `SetPoint/ClearAllPoints` пока кнопка в мешке.
- [x] Закрытие/disable: всегда восстанавливать кнопки в исходные места, затем применять policy hide/show (без уезда MinimapCluster).
- [x] Покрытие fallback-скана: убрать случайный batch-limit, перейти на детерминированный проход по отсортированным `_G`-кандидатам.
- [x] Упростить UI-кнопку мешка (убрать black-square фон, оставить чистый и читаемый toggler).
