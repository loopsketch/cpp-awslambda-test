# cpp-awslambda-test
AWS LambdaでC++ OpenCVを動作させるテスト

### 概要
- Lambda関数をC++で記述できるようにする
  - 開発環境が汚れないようにしたい(Dockerイメージで開発できる)
  - OpenCVを組込む
  - S3から画像を入力し画像処理を行い、結果を出力できる

### 検討結果
- S3から画像を入力しグレースケール化した画像バイナリをbase64で返す関数ができた
- バイナリで出力することができなさそうだが、base64化するユーティリティ関数があったのでbase64で出力することとした

### ビルド方法
- Dockerイメージをビルドします (手元環境で30分くらいかかった)
  ```
  $ docker build -t aws_lambda_cpp .
  ```

- ビルドしたイメージをrunします
  ```
  $ docker run --rm -it -v `pwd`:/home aws_lambda_cpp:latest /bin/bash
  ```

- イメージ内でアプリケーションをビルドし、デプロイ用のzipまで作ります
  ```
  # mkdir build
  # cd build
  # cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=~/install
  # make
  # make aws-lambda-package-demo
  # exit
  ```

- ホストの方でaws-cliを使ってLambda関数を作成します
  ```
  $ aws lambda create-function --function-name lambda_demo \
    --role arn:aws:iam::321515618692:role/lambda_demo --runtime provided \
    --timeout 15 --memory-size 128 --handler demo --zip-file fileb://build/demo.zip
  ```
  - roleはこういう感じのを設定
    ```(arn:aws:iam::321515618692:role/lambda_demo)
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": {
                  "Service": "lambda.amazonaws.com"
              },
              "Action": "sts:AssumeRole"
          }
      ]
    }
    ```

- Lambda関数を実行します
  - payloadにs3bucket(バケット名)とs3key(ファイルパス)をJSON形式でパラメータを渡します
    - 元画像(lenna.png)をグレースケールでpngエンコードしたものがBASE64形式で返されます(`temp.txt`)
    - base64コマンドを使ってデコードし、`out.png`を出力しています
  ```
  $ aws lambda invoke --function-name lambda_demo \
    --payload '{"s3bucket": "lambda-test-3215-1561-8692", "s3key": "lenna.png" }' \
    temp.txt && base64 -d temp.txt > out.png && rm temp.txt
  ```

### 参考資料など
  - https://qiita.com/kyamamoto9120/items/bc487688184f13b0c5e2
    - 結構情報が古くそのままではSDKがビルドできず
    - alpine:latestではうまくビルドできずバージョン調整する必要があった
    - デプロイするパッケージへのリソースの埋め込みができず、ファイルのやり取りができなさそうだった
    - 汎用性も考えS3にリソースを置いて処理ができるよう下記を参考に構築、SDKとruntimeの構築が必要だった
      - https://github.com/awslabs/aws-lambda-cpp/blob/master/examples/s3/README.md
