param([string]$BaseUrl = 'http://127.0.0.1:8080')

$ErrorActionPreference = 'Stop'
$checks = 0

function Request {
    param([string]$Method, [string]$Path, [string]$Token = '', $Body = $null)
    $args = @{
        Uri = "$BaseUrl$Path"
        Method = $Method
        SkipHttpErrorCheck = $true
    }
    if ($Token) { $args.Headers = @{ Authorization = "Bearer $Token" } }
    if ($null -ne $Body) {
        $args.ContentType = 'application/json'
        $args.Body = $Body | ConvertTo-Json -Depth 8 -Compress
    }
    $response = Invoke-WebRequest @args
    $json = if ($response.Content) { $response.Content | ConvertFrom-Json } else { $null }
    return [pscustomobject]@{ Status = $response.StatusCode; Json = $json }
}

function Check {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:checks++
    Write-Host "PASS: $Message"
}

$suffix = [guid]::NewGuid().ToString('N')
$user = Request POST '/auth/register' -Body @{
    email = "lab5-$suffix@test.md"; password = 'parola123'; name = 'Lab5 Tester'
}
$other = Request POST '/auth/register' -Body @{
    email = "lab5-other-$suffix@test.md"; password = 'parola123'; name = 'Other Tester'
}
Check ($user.Status -eq 201 -and $other.Status -eq 201) 'registration returns 201'
$duplicate = Request POST '/auth/register' -Body @{
    email = "lab5-$suffix@test.md"; password = 'parola123'; name = 'Duplicate'
}
Check ($duplicate.Status -eq 409 -and $duplicate.Json.error.code -eq 'EMAIL_TAKEN') 'base duplicate-email error survives'
$token = $user.Json.token
$otherToken = $other.Json.token
$profile = Request GET '/profile' -Token $token
Check ($profile.Status -eq 200 -and $profile.Json.role -eq 'user') 'profile exposes default warehouse role'

$health = Request GET '/health'
Check ($health.Status -eq 200 -and $health.Json.status -eq 'ok') 'base health route survives'
$noToken = Request GET '/notes'
Check ($noToken.Status -eq 401 -and $noToken.Json.error.code -eq 'UNAUTHORIZED') 'base auth filter survives'
$note = Request POST '/notes' -Token $token -Body @{ title = 'Покупки'; content = 'молоко' }
$notes = Request GET '/notes?search=%D0%9F%D0%BE%D0%BA%D1%83%D0%BF' -Token $token
Check ($note.Status -eq 201 -and $notes.Json.total -eq 1) 'base notes CRUD and search survive'
$otherNote = Request GET "/notes/$($note.Json.id)" -Token $otherToken
Check ($otherNote.Status -eq 404 -and $otherNote.Json.error.code -eq 'NOT_FOUND') 'base notes ownership survives'

$locations = Request GET '/locations?limit=2' -Token $token
Check ($locations.Status -eq 200 -and $locations.Json.total -eq 5 -and $locations.Json.items.Count -eq 2) 'locations paginate'
$destination = Request GET '/locations/3' -Token $token
Check ($destination.Status -eq 200 -and $destination.Json.qrCodeValue -eq 'STH-LOC-B1') 'location detail returns QR value'

$draft = @{
    title = 'Взять коробку'; description = 'Отнести в точку B1'; priority = 'high'
    sourceLocationId = 1; destinationLocationId = 3; dueAt = '2026-11-15T12:00:00Z'
}
$invalidDraft = @{} + $draft
$invalidDraft.destinationLocationId = 99
$invalid = Request POST '/tasks' -Token $token -Body $invalidDraft
Check ($invalid.Status -eq 400 -and $invalid.Json.error.code -eq 'VALIDATION_ERROR') 'task location validation returns contract error'
$created = Request POST '/tasks' -Token $token -Body $draft
$taskId = $created.Json.id
Check ($created.Status -eq 201 -and $taskId -gt 0 -and $created.Json.status -eq 'new') 'task creation assigns id and status'

$foreign = Request GET "/tasks/$taskId" -Token $otherToken
Check ($foreign.Status -eq 404 -and $foreign.Json.error.code -eq 'NOT_FOUND') 'other user cannot read task'
$searched = Request GET '/tasks?search=%D0%BA%D0%BE%D1%80%D0%BE%D0%B1%D0%BA%D1%83' -Token $token
Check ($searched.Status -eq 200 -and $searched.Json.total -eq 1) 'task search runs on server'

$secondDraft = @{} + $draft
$secondDraft.title = 'Вторая коробка'
$second = Request POST '/tasks' -Token $token -Body $secondDraft
$firstPage = Request GET '/tasks?limit=1&page=1' -Token $token
$secondPage = Request GET '/tasks?limit=1&page=2' -Token $token
Check ($second.Status -eq 201 -and $firstPage.Json.total -eq 2 -and $firstPage.Json.items.Count -eq 1 -and $secondPage.Json.items.Count -eq 1 -and $firstPage.Json.items[0].id -ne $secondPage.Json.items[0].id) 'task pages do not overlap'

$edited = @{} + $draft
$edited.title = 'Обновлённая коробка'
$updated = Request PUT "/tasks/$taskId" -Token $token -Body $edited
Check ($updated.Status -eq 200 -and $updated.Json.title -eq $edited.title) 'task update persists'
$premature = Request PATCH "/tasks/$taskId/status" -Token $token -Body @{ status = 'completed' }
Check ($premature.Status -eq 400 -and $premature.Json.error.code -eq 'VALIDATION_ERROR') 'completion requires QR'
$wrongQr = Request POST "/tasks/$taskId/qr-confirmation" -Token $token -Body @{ qrCodeValue = 'STH-LOC-A1' }
Check ($wrongQr.Status -eq 400 -and $wrongQr.Json.error.code -eq 'VALIDATION_ERROR') 'wrong destination QR is rejected'
$rightQr = Request POST "/tasks/$taskId/qr-confirmation" -Token $token -Body @{ qrCodeValue = 'STH-LOC-B1' }
Check ($rightQr.Status -eq 201 -and $rightQr.Json.locationId -eq 3) 'destination QR is recorded'
$completed = Request PATCH "/tasks/$taskId/status" -Token $token -Body @{ status = 'completed'; comment = 'Передано' }
Check ($completed.Status -eq 200 -and $completed.Json.status -eq 'completed' -and $completed.Json.completedAt) 'task completes after QR'
$completedEdit = @{} + $draft
$completedEdit.destinationLocationId = 4
$cannotMove = Request PUT "/tasks/$taskId" -Token $token -Body $completedEdit
Check ($cannotMove.Status -eq 400) 'completed destination cannot change'
$history = Request GET "/tasks/$taskId/history" -Token $token
Check ($history.Status -eq 200 -and $history.Json.total -eq 2 -and $history.Json.items[0].previousStatus -eq 'new' -and $history.Json.items[0].newStatus -eq 'completed') 'status history is recorded'

$secondId = $second.Json.id
$firstScan = Request POST "/tasks/$secondId/qr-confirmation" -Token $token -Body @{ qrCodeValue = 'STH-LOC-B1' }
$movedDraft = @{} + $secondDraft
$movedDraft.destinationLocationId = 4
$moved = Request PUT "/tasks/$secondId" -Token $token -Body $movedDraft
$staleScan = Request PATCH "/tasks/$secondId/status" -Token $token -Body @{ status = 'completed' }
Check ($firstScan.Status -eq 201 -and $moved.Status -eq 200 -and $staleScan.Status -eq 400) 'editing destination invalidates old QR'
$sharedQr = Request POST "/tasks/$secondId/qr-confirmation" -Token $token -Body @{ qrCodeValue = 'STH-LOC-B1' }
$secondCompleted = Request PATCH "/tasks/$secondId/status" -Token $token -Body @{ status = 'completed' }
Check ($sharedQr.Status -eq 201 -and $sharedQr.Json.locationId -eq 4 -and $secondCompleted.Status -eq 200 -and $secondCompleted.Json.status -eq 'completed') 'printed demo QR confirms tasks at other destinations'

$deleted = Request DELETE "/tasks/$taskId" -Token $token
$gone = Request GET "/tasks/$taskId" -Token $token
Check ($deleted.Status -eq 204 -and $gone.Status -eq 404) 'delete returns 204 and removes task'
Write-Host "PASS: $checks checks passed"
