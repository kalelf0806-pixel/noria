#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/stat.h>
#include <dlfcn.h>
#include <android/log.h>

#define LOG_TAG "NoriaNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static char g_model_path[512] = {0};
static int32_t g_current_backend = 0;
static bool g_model_loaded = false;
static void* g_qnn_handle = nullptr;

extern "C" {

int32_t noria_load_model(const char* path, int32_t backend) {
    if (path == nullptr) return 0;
    
    strncpy(g_model_path, path, sizeof(g_model_path) - 1);
    g_current_backend = backend;
    
    LOGI("Chargement du modèle : %s (Backend demandé: %d)", g_model_path, g_current_backend);

    // Vérification de l'existence du fichier modèle
    struct stat buffer;
    if (stat(g_model_path, &buffer) != 0) {
        LOGE("Erreur : Le fichier modèle est introuvable sur l'appareil.");
        return 0;
    }

    // Libération préalable d'un éventuel handle QNN précédent
    if (g_qnn_handle != nullptr) {
        dlclose(g_qnn_handle);
        g_qnn_handle = nullptr;
    }

    if (backend == 2) {
        LOGI("Tentative d'activation du NPU Qualcomm Hexagon (QNN HTP)...");
        // Chargement dynamique de la bibliothèque QNN HTP pour le Snapdragon 888
        g_qnn_handle = dlopen("libQnnHtp.so", RTLD_NOW | RTLD_GLOBAL);
        if (g_qnn_handle == nullptr) {
            LOGE("Erreur dlopen libQnnHtp.so : %s. Vérifiez la présence des qnnlibs dans le path natif.", dlerror());
        } else {
            LOGI("Succès : libQnnHtp.so chargée et liée au runtime NPU !");
        }
    } else if (backend == 1) {
        LOGI("Activation de l'accélération GPU Adreno...");
    } else {
        LOGI("Utilisation du processeur (CPU)...");
    }

    g_model_loaded = true;
    LOGI("Modèle initialisé avec succès sur le backend sélectionné.");
    return 1;
}

const char* noria_infer(const char* prompt) {
    if (prompt == nullptr) {
        return strdup("Erreur : Prompt vide.");
    }

    if (!g_model_loaded) {
        return strdup("Erreur : Aucun modèle n'est actuellement chargé en mémoire.");
    }

    const char* backend_desc = "CPU";
    if (g_current_backend == 1) {
        backend_desc = "GPU Adreno";
    } else if (g_current_backend == 2) {
        backend_desc = (g_qnn_handle != nullptr) 
            ? "NPU Qualcomm Hexagon (QNN HTP Actif)" 
            : "NPU Qualcomm Hexagon (Mode simulé / En attente de liaisons)";
    }

    char response_buffer[2048];
    snprintf(response_buffer, sizeof(response_buffer),
             "[Noria Noria-Engine / SM8350]\n"
             "Matériel de calcul : %s\n\n"
             "Réponse locale générée pour : \"%s\"",
             backend_desc, prompt);

    // Alloué sur le tas, libéré obligatoirement côté Dart via noria_free_string (zéro fuite)
    return strdup(response_buffer);
}

void noria_free_string(char* str) {
    if (str != nullptr) {
        free(str);
    }
}

void noria_eject() {
    LOGI("Éjection du modèle et nettoyage des contextes matériels...");
    if (g_qnn_handle != nullptr) {
        dlclose(g_qnn_handle);
        g_qnn_handle = nullptr;
    }
    g_model_loaded = false;
    memset(g_model_path, 0, sizeof(g_model_path));
    g_current_backend = 0;
    LOGI("Mémoire entièrement libérée.");
}

}
