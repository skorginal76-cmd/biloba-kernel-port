# Uyumluluk Patch'leri

Bu dizin, otomatik sed/regex fix'lerinin cozemedigi derleme hatalari icin
manuel patch dosyalarini icerir.

## Patch Format

- `.patch` veya `.diff` uzantili olmali
- `patch -p1` ile uygulanabilir olmali (linux kaynak kokunden)
- Sirayla uygulanir (alfabetik)

## Bilinen 5.10 Uyumsuzluklari

### 1. `of_device_id` table empty terminator
Bazi Mediatek driver'larinda `of_device_id` tablosu bos sonlandirici ile
bitmiyor. 5.10'da bu zorunlu.

### 2. ` thermal_zone_device_register` parametre degisikligi
5.10'da thermal API parametreleri degisti. Eski 8 parametreli cagrilar
guncellenmeli.

### 3. `dma_buf` API degisiklikleri
5.10'da `dma_buf` attach/detach API'si degisti. GPU/Display driver'lari
etkilenebilir.

### 4. `mmgrab`/`mmdrop` -> `mmget`/`mmput`
Bazi scheduler/performance driver'larinda eski API kullanimi olabilir.

### 5. `clk_hw_register_fixed_factor` API
5.10'da clock API degisiklikleri. Mediatek clock driver'lari etkilenebilir.

### 6. ` regulator_register` -> `devm_regulator_register`
Bazi power driver'larinda eski API kullanimi.

### 7. `mtd` partition API
5.10'da MTD partition API degisti. NAND driver'lar etkilenebilir.

## Ornek Patch

```patch
--- a/drivers/misc/mediatek/thermal/sample_driver.c
+++ b/drivers/misc/mediatek/thermal/sample_driver.c
@@ -123,7 +123,7 @@ static int sample_probe(struct platform_device *pdev)
 	ret = thermal_zone_device_register("sample", 0, 0, priv,
-					   &sample_ops, NULL, 0, 0);
+					   &sample_ops, NULL, 0, 0, 0);
 	if (IS_ERR(tz))
 		return PTR_ERR(tz);
```

## Nasil Patch Olusturulur

1. Hata mesajini inceleyin
2. Ilgili dosyayi duzeltin
3. Patch olusturun:
   ```bash
   git diff > patches/01-fix-thermal-api.patch
   ```
4. Workflow'u tekrar calistirin
