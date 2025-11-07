# rita remote ops

## Команды для Windows машины
1. Создай рабочую папку и перейди в неё:
   ```powershell
   New-Item -ItemType Directory -Path C:\tima -Force
   Set-Location C:\tima
   ```
2. Сгенерируй SSH-ключ и придумай passphrase, если нужно:
   ```powershell
   ssh-keygen -t ed25519 -C "rita-windows"
   ```
3. Скопируй публичный ключ и добавь его в GitHub:
   ```powershell
   Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
   ```
4. Клонируй репозиторий (после того как ключ добавлен):
   ```powershell
   git clone git@github.com:hensybex/rita_repo.git
   Set-Location .\rita_repo
   git status
   ```

## Скрипт установки Node.js
Запусти на Windows-машине PowerShell **от имени администратора** и выполни:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
```

> Эта команда включает запуск локального скрипта только на текущую сессию PowerShell.

```powershell
Set-Location C:\tima\rita_repo
.\scripts\install-node.ps1
```

- Если появится сообщение, что Node.js уже установлен, но тебе нужна переустановка, добавь параметр `-Force`.
- Скрипт требует установленного `winget` (ставится вместе с приложением **App Installer** из Microsoft Store).
- После успешного выполнения появятся версии `node` и `npm`.

## Gemini CLI (коротко)
1. Проверка Node.js и npm:
   ```powershell
   node -v
   npm -v
   ```
   Если команд нет — установи LTS через `winget install OpenJS.NodeJS.LTS` и перезапусти PowerShell.
2. Установка Gemini CLI:
   ```powershell
   npm install -g @google/gemini-cli
   gemini --version
   ```
3. Задай API-ключ (разово на сессию):
   ```powershell
   $env:GEMINI_API_KEY = "сюда_ключ"
   ```
   Чтобы сохранить навсегда: `setx GEMINI_API_KEY "сюда_ключ"` и открой новое окно PowerShell.
4. Запуск ассистента:
   ```powershell
   gemini
   ```
   В меню выбери "Use Gemini API key" (или "Login with Google", если нужна браузерная авторизация).

## Рабочий процесс
- Я буду добавлять инструкции в этот репозиторий.
- На Windows-машине запускай `git pull`, чтобы получать свежие шаги.
- Gemini CLI ответы можно сохранять в подкаталог `reports/` и пушить обратно.
