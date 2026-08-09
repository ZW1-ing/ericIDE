#include "napi/native_api.h"
#include "hilog/log.h"
#include "Python.h"
#include <string>
#include <vector>
#include <cstring>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x0000
#define LOG_TAG "ERIC_IDE"

static bool g_isPythonInitialized = false;

// Base64 encode
static std::string base64Encode(const std::string &input) {
    static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string output;
    int val = 0, valb = -6;
    for (unsigned char c : input) {
        val = (val << 8) + c;
        valb += 8;
        while (valb >= 0) {
            output.push_back(encodingTable[(val >> valb) & 0x3F]);
            valb -= 6;
        }
    }
    while (output.size() % 4) output.push_back('=');
    return output;
}

static napi_value RunPythonCode(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1 || args[0] == nullptr) {
        napi_value returnValue;
        napi_create_string_utf8(env, "Error: no code argument provided.\n", NAPI_AUTO_LENGTH, &returnValue);
        return returnValue;
    }

    size_t codeLen = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &codeLen);
    std::vector<char> codeBuffer(codeLen + 1);
    napi_get_value_string_utf8(env, args[0], codeBuffer.data(), codeLen + 1, &codeLen);

    OH_LOG_INFO(LOG_APP, "Received code length: %{public}zu", codeLen);

    if (!g_isPythonInitialized) {
        Py_Initialize();
        if (!Py_IsInitialized()) {
            napi_value returnValue;
            napi_create_string_utf8(env, "Error: Failed to initialize Python engine.\n", NAPI_AUTO_LENGTH, &returnValue);
            return returnValue;
        }
        g_isPythonInitialized = true;
        OH_LOG_INFO(LOG_APP, "Python 3.13 engine initialized successfully");
    }

    // Use base64 encoding to safely pass code (avoids triple-quote and escape issues)
    std::string encoded = base64Encode(std::string(codeBuffer.data(), codeLen));

    std::string pyScript =
        "import sys, io, base64, traceback\n"
        "_b64 = '" + encoded + "'\n"
        "_code = base64.b64decode(_b64).decode('utf-8')\n"
        "_capturer = io.StringIO()\n"
        "_old_stdout = sys.stdout\n"
        "_old_stderr = sys.stderr\n"
        "sys.stdout = _capturer\n"
        "sys.stderr = _capturer\n"
        "try:\n"
        "    exec(_code, {'__name__': '__main__', '__builtins__': __builtins__})\n"
        "except Exception:\n"
        "    traceback.print_exc()\n"
        "_output = _capturer.getvalue()\n"
        "sys.stdout = _old_stdout\n"
        "sys.stderr = _old_stderr\n";

    PyObject* mainModule = PyImport_AddModule("__main__");
    PyObject* globalDict = PyModule_GetDict(mainModule);

    PyObject* evalRes = PyRun_String(pyScript.c_str(), Py_file_input, globalDict, globalDict);
    std::string resultStr = "";

    if (evalRes != nullptr) {
        Py_DECREF(evalRes);
        PyObject* outputObj = PyDict_GetItemString(globalDict, "_output");
        if (outputObj != nullptr && PyUnicode_Check(outputObj)) {
            const char* utf8Chars = PyUnicode_AsUTF8(outputObj);
            if (utf8Chars) {
                resultStr = std::string(utf8Chars);
            }
        }
        OH_LOG_INFO(LOG_APP, "Python execution OK, output length: %{public}zu", resultStr.length());
    } else {
        // Try to get the last Python error
        PyObject *pType, *pValue, *pTraceback;
        PyErr_Fetch(&pType, &pValue, &pTraceback);
        if (pValue != nullptr) {
            PyObject* pStr = PyObject_Str(pValue);
            if (pStr != nullptr) {
                const char* errStr = PyUnicode_AsUTF8(pStr);
                if (errStr) {
                    resultStr = std::string("Python error: ") + errStr + "\n";
                }
                Py_DECREF(pStr);
            }
            Py_DECREF(pValue);
        }
        if (pType) Py_DECREF(pType);
        if (pTraceback) Py_DECREF(pTraceback);

        if (resultStr.empty()) {
            resultStr = "Python execution internal error (no details).\n";
        }
        OH_LOG_ERROR(LOG_APP, "Python execution failed: %{public}s", resultStr.c_str());
    }

    napi_value returnValue;
    napi_create_string_utf8(env, resultStr.c_str(), NAPI_AUTO_LENGTH, &returnValue);
    return returnValue;
}

static napi_value RunRubyCode(napi_env env, napi_callback_info info) {
    napi_value returnValue;
    std::string msg = "[Ruby] Runtime not yet integrated. Add libruby.so to entry/libs/arm64-v8a/\n";
    napi_create_string_utf8(env, msg.c_str(), NAPI_AUTO_LENGTH, &returnValue);
    return returnValue;
}

static napi_value GetSupportedLanguages(napi_env env, napi_callback_info info) {
    napi_value returnValue;
    napi_create_string_utf8(env, "python,ruby", NAPI_AUTO_LENGTH, &returnValue);
    return returnValue;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "runPython", nullptr, RunPythonCode, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "runRuby", nullptr, RunRubyCode, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSupportedLanguages", nullptr, GetSupportedLanguages, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module ericModule = {
    1, 0, nullptr, Init, "entry", nullptr, nullptr, { 0 }
};

extern "C" __attribute__((constructor)) void registerEntryModule(void) {
    napi_module_register(&ericModule);
}
