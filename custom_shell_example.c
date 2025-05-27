#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

#define MAX_LINE 1024
#define MAX_ARGS 64

// Split input line into arguments
void parse_line(char *line, char **args, int *arg_count) {
    *arg_count = 0;
    char *token = strtok(line, " \t\r\n");
    while (token != NULL && *arg_count < MAX_ARGS - 1) {
        args[(*arg_count)++] = token;
        token = strtok(NULL, " \t\r\n");
    }
    args[*arg_count] = NULL;
}

int main() {
    char line[MAX_LINE];
    char *args[MAX_ARGS];
    int arg_count;
    pid_t pid;
    int status;

    while (1) {
        printf("mini-shell> ");
        if (fgets(line, sizeof(line), stdin) == NULL) {
            printf("\n");
            break;
        }
        if (line[0] == '\n') continue;

        parse_line(line, args, &arg_count);

        if (arg_count == 0) continue;

        if (strcmp(args[0], "exit") == 0) break;

        pid = fork();
        if (pid < 0) {
            perror("fork failed");
            exit(EXIT_FAILURE);
        } else if (pid == 0) {
            execvp(args[0], args);
            perror("exec failed");
            exit(EXIT_FAILURE);
        } else {
            waitpid(pid, &status, 0);
        }
    }

    return 0;
}
