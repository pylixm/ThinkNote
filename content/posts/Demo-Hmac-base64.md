---
type : posts
title : 「编程实例」各语言Hmac-SHA256的base64编码的实现方式
categories: [Devlopment Demo,] 
date : 2020-09-17
url: /posts/2020-09-17-hmac-sha256-base64.html 
tags : [hmac, sha256, base64]
---

> 实例来源网络，语言版本可能略有差异，请验证后使用。

## Javascript HMAC SHA256

```Javascript
<script src="http://crypto-js.googlecode.com/svn/tags/3.0.2/build/rollups/hmac-sha256.js"></script>
<script src="http://crypto-js.googlecode.com/svn/tags/3.0.2/build/components/enc-base64-min.js"></script>

<script>
  var hash = CryptoJS.HmacSHA256("Message", "secret");
  var hashInBase64 = CryptoJS.enc.Base64.stringify(hash);
  document.write(hashInBase64);
</script>
```

## PHP HMAC SHA256


```PHP 
$s = hash_hmac('sha256', 'Message', 'secret', true);
echo base64_encode($s);
Java HMAC SHA256
Dependent on Apache Commons Codec to encode in base64.

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.apache.commons.codec.binary.Base64;

public class ApiSecurityExample {
  public static void main(String[] args) {
    try {
     String secret = "secret";
     String message = "Message";

     Mac sha256_HMAC = Mac.getInstance("HmacSHA256");
     SecretKeySpec secret_key = new SecretKeySpec(secret.getBytes(), "HmacSHA256");
     sha256_HMAC.init(secret_key);

     String hash = Base64.encodeBase64String(sha256_HMAC.doFinal(message.getBytes()));
     System.out.println(hash);
    }
    catch (Exception e){
     System.out.println("Error");
    }
   }
}
```

## Groovy HMAC SHA256

```Groovy
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.security.InvalidKeyException;

def hmac_sha256(String secretKey, String data) {
 try {
    Mac mac = Mac.getInstance("HmacSHA256")
    SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey.getBytes(), "HmacSHA256")
    mac.init(secretKeySpec)
    byte[] digest = mac.doFinal(data.getBytes())
    return digest
   } catch (InvalidKeyException e) {
    throw new RuntimeException("Invalid key exception while converting to HMac SHA256")
  }
}

def hash = hmac_sha256("secret", "Message")
encodedData = hash.encodeBase64().toString()
log.info(encodedData)
```

## C# HMAC SHA256

```C#
using System.Security.Cryptography;

namespace Test
{
  public class MyHmac
  {
    private string CreateToken(string message, string secret)
    {
      secret = secret ?? "";
      var encoding = new System.Text.ASCIIEncoding();
      byte[] keyByte = encoding.GetBytes(secret);
      byte[] messageBytes = encoding.GetBytes(message);
      using (var hmacsha256 = new HMACSHA256(keyByte))
      {
        byte[] hashmessage = hmacsha256.ComputeHash(messageBytes);
        return Convert.ToBase64String(hashmessage);
      }
    }
  }
}
```

## Objective C and Cocoa HMAC SHA256

```
#import "AppDelegate.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
 NSString* key = @"secret";
 NSString* data = @"Message";

 const char *cKey = [key cStringUsingEncoding:NSASCIIStringEncoding];
 const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
 unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
 CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
 NSData *hash = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];

 NSLog(@"%@", hash);

 NSString* s = [AppDelegate base64forData:hash];
 NSLog(s);
}

+ (NSString*)base64forData:(NSData*)theData {
 const uint8_t* input = (const uint8_t*)[theData bytes];
 NSInteger length = [theData length];

 static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

 NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
 uint8_t* output = (uint8_t*)data.mutableBytes;

 NSInteger i;
 for (i=0; i < length; i += 3) {
 NSInteger value = 0;
 NSInteger j;
 for (j = i; j < (i + 3); j++) {
 value <<= 8;

 if (j < length) {  value |= (0xFF & input[j]);  }  }  NSInteger theIndex = (i / 3) * 4;  output[theIndex + 0] = table[(value >> 18) & 0x3F];
 output[theIndex + 1] = table[(value >> 12) & 0x3F];
 output[theIndex + 2] = (i + 1) < length ? table[(value >> 6) & 0x3F] : '=';
 output[theIndex + 3] = (i + 2) < length ? table[(value >> 0) & 0x3F] : '=';
 }

 return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]; }

@end

```

## Go programming language - Golang HMAC SHA256

```go
package main

import (
    "crypto/hmac"
    "crypto/sha256"
    "encoding/base64"
    "fmt"
)

func ComputeHmac256(message string, secret string) string {
    key := []byte(secret)
    h := hmac.New(sha256.New, key)
    h.Write([]byte(message))
    return base64.StdEncoding.EncodeToString(h.Sum(nil))
}

func main() {
    fmt.Println(ComputeHmac256("Message", "secret"))
}
```

## Ruby HMAC SHA256

```ruby

require 'openssl'
require "base64"

hash  = OpenSSL::HMAC.digest('sha256', "secret", "Message")
puts Base64.encode64(hash)
Python (2.7) HMAC SHA256
import hashlib
import hmac
import base64

message = bytes("Message").encode('utf-8')
secret = bytes("secret").encode('utf-8')

signature = base64.b64encode(hmac.new(secret, message, digestmod=hashlib.sha256).digest())
print(signature)
Tested with Python 2.7.6. Also, be sure not to name your python demo script the same as one of the imported libraries.
```

## Perl HMAC SHA256

```perl
use Digest::SHA qw(hmac_sha256_base64);
$digest = hmac_sha256_base64("Message", "secret");

# digest is currently: qnR8UCqJggD55PohusaBNviGoOJ67HC6Btry4qXLVZc

# Fix padding of Base64 digests
while (length($digest) % 4) {
    $digest .= '=';
}

print $digest;
# digest is now: qnR8UCqJggD55PohusaBNviGoOJ67HC6Btry4qXLVZc=
```

## Dart HMAC SHA256

```dart

import 'dart:html';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {

  String secret = 'secret';
  String message = 'Message';

  List<int> secretBytes = UTF8.encode('secret');
  List<int> messageBytes = UTF8.encode('Message');

  var hmac = new HMAC(new SHA256(), secretBytes);
  hmac.add(messageBytes);
  var digest = hmac.close();

  var hash = CryptoUtils.bytesToBase64(digest);

  // output to html page
  querySelector('#hash').text = hash;
  // hash => qnR8UCqJggD55PohusaBNviGoOJ67HC6Btry4qXLVZc=
}
```

## Swift HMAC SHA256

参考这个 [stackOverflow post](http://stackoverflow.com/questions/24099520/commonhmac-in-swift)

## Rust

参考这个库 [alco/rust-digest](https://github.com/alco/rust-digest/blob/master/hmac.rs)

## Powershell (Windows) HMAC SHA256

Mostly wrapping of .NET libraries but useful to see it in powershell's befuddling syntax. See code as gist

```
$message = 'Message'
$secret = 'secret'

$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($secret)
$signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($message))
$signature = [Convert]::ToBase64String($signature)

echo $signature
echo ($signature -eq 'qnR8UCqJggD55PohusaBNviGoOJ67HC6Btry4qXLVZc=')

```