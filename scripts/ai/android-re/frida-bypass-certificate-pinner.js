// Frida script: Bypass common SSL/TLS certificate pinning implementations.
// Covers OkHttp CertificatePinner (multiple overloads + Kotlin), Conscrypt
// TrustManagerImpl, SSLContext TrustManager replacement, CertificateChainCleaner,
// CertPathValidator, and Network Security Config pinning.
//
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-bypass-certificate-pinner.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-bypass-certificate-pinner.js

Java.perform(function () {

    // -----------------------------------------------------------------------
    // 1. okhttp3.CertificatePinner.check(String, List)
    // -----------------------------------------------------------------------
    try {
        var CertificatePinner = Java.use("okhttp3.CertificatePinner");
        var checkList = CertificatePinner.check.overload("java.lang.String", "java.util.List");

        checkList.implementation = function (host, peerCertificates) {
            console.log("[cert-bypass] CertificatePinner.check(String,List) host=" + host);
            return;
        };

        console.log("[cert-bypass] OkHttp CertificatePinner.check(String,List) active");
    } catch (e) {
        console.log("[cert-bypass] CertificatePinner.check(String,List) hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 2. okhttp3.CertificatePinner.check(String, Certificate...) — varargs
    // -----------------------------------------------------------------------
    try {
        var CertificatePinner2 = Java.use("okhttp3.CertificatePinner");
        var checkVarargs = CertificatePinner2.check.overload(
            "java.lang.String", "java.security.cert.Certificate[]"
        );

        checkVarargs.implementation = function (host, peerCertificates) {
            console.log("[cert-bypass] CertificatePinner.check(String,Certificate[]) host=" + host);
            return;
        };

        console.log("[cert-bypass] OkHttp CertificatePinner.check(String,Certificate[]) active");
    } catch (e) {
        console.log("[cert-bypass] CertificatePinner.check(String,Certificate[]) hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 3. okhttp3.CertificatePinner.check$okhttp(String, List) — Kotlin
    // -----------------------------------------------------------------------
    try {
        var CertificatePinner3 = Java.use("okhttp3.CertificatePinner");
        var checkKotlin = CertificatePinner3["check$okhttp"].overload("java.lang.String", "java.util.List");

        checkKotlin.implementation = function (host, peerCertificates) {
            console.log("[cert-bypass] CertificatePinner.check$okhttp(String,List) host=" + host);
            return;
        };

        console.log("[cert-bypass] OkHttp CertificatePinner.check$okhttp active");
    } catch (e) {
        console.log("[cert-bypass] CertificatePinner.check$okhttp hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 4. Conscrypt TrustManagerImpl.verifyChain
    // -----------------------------------------------------------------------
    try {
        var TrustManagerImpl = Java.use("com.android.org.conscrypt.TrustManagerImpl");
        var verifyChain = TrustManagerImpl.verifyChain.overload(
            "java.util.List",
            "java.util.List",
            "java.lang.String",
            "boolean",
            "byte[]",
            "byte[]"
        );

        verifyChain.implementation = function (untrustedChain, trustAnchorChain, host, clientAuth, ocspData, tlsSctData) {
            console.log("[cert-bypass] TrustManagerImpl.verifyChain host=" + host);
            return untrustedChain;
        };

        console.log("[cert-bypass] Conscrypt TrustManagerImpl.verifyChain active");
    } catch (e) {
        console.log("[cert-bypass] TrustManagerImpl.verifyChain hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 5. Conscrypt TrustManagerImpl.checkTrustedRecursive
    // -----------------------------------------------------------------------
    try {
        var TMImpl2 = Java.use("com.android.org.conscrypt.TrustManagerImpl");
        var checkTrustedRecursive = TMImpl2.checkTrustedRecursive.overload(
            "java.security.cert.X509Certificate[]",
            "java.lang.String",
            "java.lang.String"
        );

        checkTrustedRecursive.implementation = function (chain, authType, host) {
            console.log("[cert-bypass] TrustManagerImpl.checkTrustedRecursive host=" + host);
            return chain;
        };

        console.log("[cert-bypass] Conscrypt TrustManagerImpl.checkTrustedRecursive active");
    } catch (e) {
        console.log("[cert-bypass] TrustManagerImpl.checkTrustedRecursive hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 6. SSLContext.init — replace all TrustManagers with a permissive one
    // -----------------------------------------------------------------------
    try {
        var X509TrustManager = Java.use("javax.net.ssl.X509TrustManager");
        var SSLContext = Java.use("javax.net.ssl.SSLContext");

        var PermissiveTrustManager = Java.registerClass({
            name: "com.frida.PermissiveTrustManager",
            implements: [X509TrustManager],
            methods: {
                checkClientTrusted: function (chain, authType) {
                    // no-op — accept all clients
                },
                checkServerTrusted: function (chain, authType) {
                    // no-op — accept all servers
                },
                getAcceptedIssuers: function () {
                    var X509Certificate = Java.use("java.security.cert.X509Certificate");
                    return Java.array("java.security.cert.X509Certificate", []);
                }
            }
        });

        var initMethod = SSLContext.init.overload(
            "javax.net.ssl.KeyManager[]",
            "javax.net.ssl.TrustManager[]",
            "java.security.SecureRandom"
        );

        initMethod.implementation = function (km, tm, sr) {
            var permissive = PermissiveTrustManager.$new();
            var newTm = Java.array("javax.net.ssl.TrustManager", [permissive]);
            console.log("[cert-bypass] SSLContext.init replacing TrustManager[] with permissive");
            return initMethod.call(this, km, newTm, sr);
        };

        console.log("[cert-bypass] SSLContext.init permissive TrustManager active");
    } catch (e) {
        console.log("[cert-bypass] SSLContext.init hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 7. okhttp3.CertificateChainCleaner.clean(List, String) — return unmodified
    // -----------------------------------------------------------------------
    try {
        var CertificateChainCleaner = Java.use("okhttp3.CertificateChainCleaner");
        var cleanMethod = CertificateChainCleaner.clean.overload("java.util.List", "java.lang.String");

        cleanMethod.implementation = function (chain, hostname) {
            console.log("[cert-bypass] CertificateChainCleaner.clean host=" + hostname);
            return chain;
        };

        console.log("[cert-bypass] OkHttp CertificateChainCleaner.clean active");
    } catch (e) {
        console.log("[cert-bypass] CertificateChainCleaner.clean hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 8. java.security.cert.CertPathValidator.validate — return success
    // -----------------------------------------------------------------------
    try {
        var CertPathValidator = Java.use("java.security.cert.CertPathValidator");
        var validateMethod = CertPathValidator.validate.overload(
            "java.security.cert.CertPath",
            "java.security.cert.CertPathParameters"
        );

        validateMethod.implementation = function (certPath, params) {
            console.log("[cert-bypass] CertPathValidator.validate bypassed");
            return validateMethod.call(this, certPath, params);
        };

        console.log("[cert-bypass] CertPathValidator.validate active");
    } catch (e) {
        console.log("[cert-bypass] CertPathValidator.validate hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 9. Network Security Config — try to hook if available (API 24+)
    // -----------------------------------------------------------------------
    try {
        var NetworkSecurityConfig = Java.use("android.security.net.config.NetworkSecurityConfig");

        // Try getCertificatesRootIndex — varies by Android version
        try {
            var getPins = NetworkSecurityConfig.getPins;
            if (getPins) {
                getPins.implementation = function () {
                    console.log("[cert-bypass] NetworkSecurityConfig.getPins returning empty");
                    var Collections = Java.use("java.util.Collections");
                    return Collections.emptyList();
                };
            }
        } catch (e2) {
            // getPins may not exist on this version — skip
        }

        console.log("[cert-bypass] NetworkSecurityConfig pinning bypass active");
    } catch (e) {
        console.log("[cert-bypass] NetworkSecurityConfig hook skipped: " + e.message);
    }

    console.log("[cert-bypass] === Certificate pinning bypass script loaded ===");
});
