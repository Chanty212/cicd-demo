# ============================================
# PowerShell Script: run_pipeline_demo_ngrok.ps1
# Purpose: Launch Jenkins, ngrok, and perform demo Git commit
# Outputs ngrok logs in same window for recording
# ============================================

# --- User Configuration ---
$JenkinsContainerName = "jenkins"
$JenkinsPort = 8080
$JenkinsVolume = "$env:USERPROFILE\jenkins_home"
$NgrokPath = "C:\Users\Veteran\AppData\Local\Microsoft\WindowsApps\ngrok.exe
$GitRepoPath = "https://github.com/Chanty212/CICD.git"   
$TestCommitMessage = "Demo: automated pipeline test"
$NgrokLogFile = "$env:TEMP\ngrok.log"

# --- 1. Start Jenkins Docker Container ---
Write-Host "`n=== Checking Jenkins container ==="
$container = docker ps -a --filter "name=$JenkinsContainerName" --format "{{.Names}}"
if ($container -eq $JenkinsContainerName) {
    Write-Host "Jenkins container exists. Starting..."
    docker start $JenkinsContainerName
} else {
    Write-Host "Jenkins container not found. Creating and starting new container..."
    docker run -d --name $JenkinsContainerName `
        -p $JenkinsPort:8080 -p 50000:50000 `
        -v "$JenkinsVolume:/var/jenkins_home" `
        jenkins/jenkins:lts
}

# --- 2. Show initial admin password if first run ---
Start-Sleep -Seconds 5
$adminPassFile = "$JenkinsVolume\secrets\initialAdminPassword"
if (Test-Path $adminPassFile) {
    $adminPass = Get-Content $adminPassFile
    Write-Host "`nInitial Jenkins admin password: $adminPass`n"
} else {
    Write-Host "`nJenkins already initialized or password file not found.`n"
}

# --- 3. Start ngrok in same PowerShell window ---
Write-Host "=== Starting ngrok to expose Jenkins ===`n"
Write-Host "Ngrok logs will appear below. Press Ctrl+C to stop ngrok after recording."
Start-Process -FilePath $NgrokPath -ArgumentList "http $JenkinsPort --log=stdout" -NoNewWindow -RedirectStandardOutput $NgrokLogFile -PassThru | Out-Null

# Wait a few seconds for ngrok to start
Start-Sleep -Seconds 5

# Fetch ngrok public URL automatically
try {
    $ngrokApi = Invoke-RestMethod -Uri http://127.0.0.1:4040/api/tunnels
    $publicUrl = $ngrokApi.tunnels[0].public_url
    Write-Host "`n✅ Ngrok public URL: $publicUrl"
    Write-Host "Use this URL as the GitHub webhook payload URL:`n$publicUrl/github-webhook/`n"
} catch {
    Write-Host "⚠ Could not fetch ngrok URL automatically. Open http://127.0.0.1:4040 to see public URL."
}

# --- 4. Perform demo Git commit & push ---
Write-Host "=== Performing demo Git commit & push ===`n"
Set-Location $GitRepoPath
# Make a small change for demo
Add-Content README.md "# $(Get-Date) Demo change"
git add README.md
git commit -m "$TestCommitMessage"
git push

Write-Host "`nDemo Git commit pushed. Now watch GitHub, ngrok, Jenkins, and WebEx for pipeline execution.`n"

# --- 5. Recording Instructions ---
Write-Host "=== Recording Checklist ==="
Write-Host "1. GitHub commit page with timestamp 'now'"
Write-Host "2. Ngrok terminal shows POST /github-webhook/ (capture this in recording)"
Write-Host "3. Jenkins job auto-triggered"
Write-Host "4. Jenkins Console Output shows pytest passed"
Write-Host "5. WebEx space receives bot notification"
Write-Host "`nPress Enter to exit script after recording..."
Read-Host
