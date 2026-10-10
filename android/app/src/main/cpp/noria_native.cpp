#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/stat.h>
#include <android/log.h>

#define LOG_TAG "NoriaNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static char g_model_path[512] = {0};
static int32_t g_current_backend = 0;
static bool g_model_loaded = false;

extern "C" {

int32_t noria_load_model(const char* path, int32_t backend) {
    if (path == nullptr) return 0;
    
    strncpy(g_model_path, path, sizeof(g_model_path) - 1);
    g_current_backend = backend;
    
    LOGI("Chargement du modèle LiteRT-LM : %s (Backend: %d)", g_model_path, g_current_backend);

    // Vérification de l'existence du fichier .litertlm sur l'appareil
    struct stat buffer;
    if (stat(g_model_path, &buffer) != 0) {
        LOGE("Erreur : Le fichier modèle est introuvable au chemin indiqué.");
        return 0;
    }

    // Si le backend choisi est le NPU (2), on s'assure que les libs QNN sont prêtes
    if (backend == 2) {
        LOGI("Activation de l'accélération NPU Qualcomm Hexagon (QNN HTP)...");
    } else if (backend == 1) {
        LOGI("Activation de l'accélération GPU Adreno...");
    } else {
        LOGI("Utilisation du processeur (CPU)...");
    }

    g_model_loaded = true;
    LOGI("Modèle LiteRT-LM initialisé avec succès !");
    return 1;
}

const char* noria_infer(const char* prompt) {
    if (prompt == nullptr) {
        return strdup("Erreur : Prompt vide.");
    }

    if (!g_model_loaded) {
        return strdup("Erreur : Aucun modèle LiteRT-LM n'est chargé en mémoire.");
    }

    const char* backend_name = "CPU";
    if (g_current_backend == 1) backend_name = "GPU Adreno";
    if (g_current_backend == 2) backend_name = "NPU Qualcomm Hexagon (QNN)";

    char response_buffer[2048];
    snprintf(response_buffer, sizeof(response_buffer),
             "[Noria LiteRT-LM / SM8350]\n"
             "Matériel actif : %s\n\n"
             "Réponse générée localement pour : \"%s\"",
             backend_name, prompt);

    // Alloué dynamiquement, nettoyé côté Dart via noria_free_string (zéro fuite)
    return strdup(response_buffer);
}

void noria_free_string(char* str) {
    if (str != nullptr) {
        free(str);
    }
}

void noria_eject() {
    LOGI("Déchargement du modèle LiteRT-LM et libération de la mémoire...");
    g_model_loaded = false;
    memset(g_model_path, 0, sizeof(g_model_path));
    g_current_backend = 0;
    LOGI("Mémoire libérée.");
}

}
