tar.exe -a -c -f pack.zip assets pack.mcmeta
git add .
git commit -a -m "Automated resourcepack upload"
git push origin pack