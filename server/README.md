# .NET + Minimal API — portul C#

Portul .NET al backend-șablonului PAM. Implementează exact
[`../openapi.yaml`](../openapi.yaml); vezi README-ul șablonului
(`../README_RO.md` / `_RU` / `_EN`) pentru contract și reguli.

## Pornire

```bash
dotnet run
```

Atât. Pachetele NuGet se restaurează automat, iar `app.db` (SQLite) și
folderul `uploads/` se creează automat la prima pornire. Cerință: .NET SDK 9
(`dotnet --version`).

- Env: `PORT` (implicit 8080), `JWT_SECRET` (implicit `dev-secret-change-me`).
  `PORT` câștigă întotdeauna — URL-ul e forțat din cod (`app.Run(...)` în
  `Program.cs`), deci `ASPNETCORE_URLS` sau `launchSettings.json` nu îl pot
  suprascrie.
- Upload-urile sunt limitate la 5 MB per fișier (`POST /files` răspunde 400
  `VALIDATION_ERROR` peste limită). Setările implicite — CORS deschis,
  secretul JWT de dev, limita de 5 MB — sunt pentru laborator, nu pentru
  producție.
- Descărcările (`GET /files/{id}`) pleacă cu `Content-Disposition: attachment`
  și `Content-Security-Policy: default-src 'none'; sandbox`: oricine poate
  încărca `text/html` sau `image/svg+xml`, iar fără aceste antete un link
  deschis direct în browser ar rula scriptul atacatorului pe originea API-ului
  (stored XSS). `Image.network`/`<img>` ignoră ambele antete, deci afișarea
  imaginilor în laborator nu se schimbă — dar șablonul rămâne o configurație
  de laborator, nu de producție.

## Verificarea contra contractului

```bash
# cu serverul pornit:
cd ../conformance
dart pub get
dart run bin/conformance.dart --base-url http://localhost:8080
```

## Structura

```
Program.cs — pornire: env, toate rutele, middleware (erori, CORS)
Db.cs      — schema SQLite, aplicată automat la pornire + helperul Cmd()
Auth.cs    — register/login/me, parole PBKDF2, JWT (HS256, scris de mână)
Notes.cs   — entitatea-exemplu: CRUD + paginare + căutare
Files.cs   — upload multipart, download binar
Errors.cs  — formatul standard de eroare + middleware-ul global de erori
```

Fără controllere MVC și fără EF Core: rute Minimal API și SQL parametrizat
prin `Microsoft.Data.Sqlite` — fiecare interogare rămâne vizibilă în cod.

Parolele sunt hash-uite cu PBKDF2-HMAC-SHA256 (100k iterații, salt aleatoriu)
prin `Rfc2898DeriveBytes.Pbkdf2` din BCL — niciun pachet extern; formatul
stocat este `iterații:salt:hash` (identic cu referința Dart). JWT-ul este
implementat manual (~40 de linii în `Auth.cs`), ca să vezi exact ce este un
token — fără pachetele `JwtBearer`/`System.IdentityModel`, deci și fără
capcana lor `MapInboundClaims`, care redenumește pe tăcute claim-ul `sub`.

Corpurile JSON invalide devin 400 `VALIDATION_ERROR` (nu 500): legarea
parametrilor aruncă excepție (`ThrowOnBadRequest`, în `Program.cs`), iar
middleware-ul din `Errors.cs` o transformă în formatul standard de eroare.

## Adaugă-ți propria entitate

`Notes.cs` este șablonul — copiază-l:

1. Adaugă un `CREATE TABLE` pentru entitatea ta în `Db.cs` (cu o coloană
   `user_id` dacă aparține unui utilizator).
2. Copiază `Notes.cs` în, de exemplu, `Recipes.cs`; redenumește tabelul,
   recordurile și câmpurile JSON.
3. Înregistrează noile rute în `Program.cs`, lângă grupul `/notes`
   (păstrează `.AddEndpointFilter(Auth.RequireAuth)` pe grup).
4. Repornește, testează cu `curl` sau cu aplicația ta Flutter, apoi rulează
   din nou suita de conformitate ca să confirmi că contractul de bază încă
   trece.
