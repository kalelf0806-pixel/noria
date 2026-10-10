#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

extern "C" {

static int32_t g_current_backend = 0;
static bool g_model_loaded = false;

int32_t noria_load_model(const char* path, int32_t backend) {
    if (path == nullptr) return 0;
    
    g_current_backend = backend;
    g_model_loaded = true;
    
    // Logique d'initialisation (CPU = 0, GPU = 1, NPU Hexagon = 2)
    // Ici, les bibliothèques QNN de /qnnlibs s'initialiseront si backend == 2.
    
    return 1; // 1 = Succès
}

const char* noria_infer(const char* prompt) {
    if (prompt == nullptr) {
        return strdup("Erreur : Prompt vide ou invalide.");
    }

    char buffer[2048];
    snprintf(buffer, sizeof(buffer),
             "[Noria Natif / SM8350 - Backend %d]\n"
             "Modèle actif. Analyse du prompt : \"%s\"", 
             g_current_backend, prompt);

    // strdup alloue dynamiquement sur le tas (heap).
    // La mémoire devra être libérée côté Dart après la lecture.
    return strdup(buffer);
}

// Fonction indispensable pour libérer la chaîne allouée par strdup() en C++
void noria_free_string(char* str) {
    if (str != nullptr) {
        free(str);
    }
}

void noria_eject() {
    g_model_loaded = false;
    g_current_backend = 0;
    // Libération des contextes natifs (KV Cache / Poids)
}

}
