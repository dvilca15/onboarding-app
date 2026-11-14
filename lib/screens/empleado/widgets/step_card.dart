import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';
import 'task_row.dart';
import '../../../theme/app_theme.dart';

class StepCard extends StatelessWidget {
  final StepConProgreso step;
  final int numero;
  final int idOnboarding;
  final bool expandido;
  final VoidCallback onToggle;
  final Future<void> Function(int idTask) onCompletarTask;
  final Future<void> Function(int idTask, List<Map<String, String>> respuestas)?
      onEnviarFormulario;

  const StepCard({
    super.key,
    required this.step,
    required this.numero,
    required this.idOnboarding,
    required this.expandido,
    required this.onToggle,
    required this.onCompletarTask,
    this.onEnviarFormulario,
  });

  @override
  Widget build(BuildContext context) {
    final bloqueada = step.bloqueada;
    final colorStep = step.todoCompleto
        ? AppColors.success
        : step.enProgreso
            ? AppColors.primary
            : AppColors.textSubtle;

    return Opacity(
      opacity: bloqueada ? 0.6 : 1,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bloqueada ? AppColors.surfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: step.todoCompleto
              ? AppColors.success.withOpacity(0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F1C1917),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cabecera ──────────────────────────────────────
          InkWell(
            onTap: bloqueada ? null : onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: step.todoCompleto
                          ? AppColors.success
                          : colorStep.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: bloqueada
                          ? const Icon(Icons.lock_rounded,
                              color: AppColors.textSubtle, size: 18)
                          : step.todoCompleto
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : Text('$numero',
                              style: TextStyle(
                                  color: colorStep,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.titulo,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: step.todoCompleto
                                  ? AppColors.textMuted
                                  : AppColors.text,
                              decoration: step.todoCompleto
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                        const SizedBox(height: 2),
                        if (bloqueada)
                          Text(
                            step.bloqueadaPor != null
                                ? 'Completa «${step.bloqueadaPor}» para desbloquear'
                                : 'Completa la etapa anterior para desbloquear',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSubtle),
                          )
                        else
                        Row(children: [
                          Text('${step.completadas}/${step.totalTasks} tareas',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorStep,
                                  fontWeight: FontWeight.w500)),
                          if (step.duracionDias != null) ...[
                            const Text(' · ',
                                style: TextStyle(
                                    color: AppColors.textSubtle, fontSize: 12)),
                            Text('${step.duracionDias} días',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSubtle)),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  if (bloqueada)
                    const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textSubtle, size: 20)
                  else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${step.porcentaje}%',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorStep)),
                      const SizedBox(height: 2),
                      Icon(
                        expandido
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.textSubtle, size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Barra de progreso ─────────────────────────────
          if (step.totalTasks > 0 && !bloqueada)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: step.totalTasks > 0
                      ? step.completadas / step.totalTasks
                      : 0,
                  backgroundColor: AppColors.bg,
                  valueColor: AlwaysStoppedAnimation<Color>(colorStep),
                  minHeight: 4,
                ),
              ),
            ),

          // ── Descripción ───────────────────────────────────
          if (expandido &&
              !bloqueada &&
              step.descripcion != null &&
              step.descripcion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(step.descripcion!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
              ),
            ),

          // ── Lista de tasks ────────────────────────────────
          if (expandido && !bloqueada && step.tasks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Divider(height: 1, color: AppColors.bg),
            ),
            ...step.tasks.map((t) => TaskRow(
                  task: t,
                  idOnboarding: idOnboarding,
                  onCompletar: () => onCompletarTask(t.idTask),
                  onEnviarFormulario: onEnviarFormulario,
                )),
          ],

          if (expandido && !bloqueada && step.tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Esta etapa no tiene tareas.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSubtle)),
            ),

          const SizedBox(height: 4),
        ],
      ),
    ),
    );
  }
}
