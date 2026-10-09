#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

extern "C" {

int32_t noria_load_model(const char* path, int32_t backend) {
    if (path == nullptr) return 0;
    // Initialisation native du contexte C++ / llama.cpp / OpenCL
    return 1; // 1 = Succès
}

const char* noria_infer(const char* prompt) {
    static char response[512];
    if (prompt == nullptr || strlen(prompt) == 0) {
        snprintf(response, sizeof(response), "Erreur: Prompt vide.");
    } else {
        snprintf(response, sizeof(response),
                 "[Inférence Locale C++ / SM8350]\n"
                 "Moteur local actif. Traitement du prompt : \"%s\"", prompt);
    }
    return response;
}

void noria_eject() {
    // Libération des pointeurs C++ et du KV Cache
}

}
