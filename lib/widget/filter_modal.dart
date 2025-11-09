import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/map_bloc.dart';
import '../events/map_event.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:consultoria_chat_bot/services/analytics_service.dart';

class FilterModal extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> activities;
	final double computedMaxDistance;
	final int sliderDivisions;
	final String? initialCategory;
  final String? initialActivity;
	final double initialDistance;
	final String? initialSeason;
	final Color primaryColor;
	final TextEditingController searchController;
	final void Function()? onFiltersApplied;

	const FilterModal({
		super.key,
		
		
		required this.computedMaxDistance,
		required this.sliderDivisions,
		required this.initialCategory,
		required this.initialActivity,
		required this.initialDistance,
		required this.initialSeason,
		required this.primaryColor,
		required this.searchController,
		this.onFiltersApplied, required this.categories, required this.activities,
	});

	@override
	State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
	late String? tempCategory;
	late String? tempActivity;
	late double tempDistance;
	

	@override
	void initState() {
		super.initState();
		tempCategory = widget.initialCategory;
		tempActivity = widget.initialActivity;
		tempDistance = widget.initialDistance;
		
	}

		Widget buildDropdown({
			required String? currentValue,
			required List<Map<String, dynamic>> values,
			required ValueChanged<String?> onChanged,
		}) {
			final lang = Localizations.localeOf(context).languageCode;
			return InputDecorator(
				decoration: InputDecoration(
					hintText: AppLocalizations.of(context)!.todas,
					border: OutlineInputBorder(
						borderRadius: BorderRadius.circular(12),
						borderSide: BorderSide(color: Colors.grey.shade300),
					),
					focusedBorder: OutlineInputBorder(
						borderRadius: const BorderRadius.all(Radius.circular(12)),
						borderSide: BorderSide(color: widget.primaryColor),
					),
					contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
				),
				child: DropdownButtonHideUnderline(
					child: DropdownButton<String?>(
						value: currentValue,
						hint: Text(AppLocalizations.of(context)!.todas),
						isExpanded: true,
						items: [
							DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.todas)),
														...values.map((value) {
																final id = value['id']?.toString();
																String label = id ?? '';
																try {
																	final nombre = value['nombre'];
																	String? pickFromMap(Map map, String code) {
																		final v = map[code];
																		if (v is String && v.trim().isNotEmpty) return v;
																		return null;
																	}
																	if (nombre is Map) {
																		// prefer current lang, then es, then en, then any non-empty string
																		label = pickFromMap(nombre, lang) ??
																						pickFromMap(nombre, 'es') ??
																						pickFromMap(nombre, 'en') ??
																						(() {
																							for (final entry in nombre.values) {
																								if (entry is String && entry.trim().isNotEmpty) {
																									return entry;
																								}
																							}
																							return id ?? '';
																						})();
																	} else if (nombre is String && nombre.trim().isNotEmpty) {
																		label = nombre;
																	}
																} catch (_) {
																	// ignore and fallback to id
																}
																if (label.trim().isEmpty) label = id ?? '';
																return DropdownMenuItem(value: id, child: Text(label));
														}),
						],
						onChanged: onChanged,
					),
				),
			);
		}

	@override
	Widget build(BuildContext context) {
		final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
					fontWeight: FontWeight.w600,
					color: widget.primaryColor,
				);
        final distanceLabel = tempDistance <= 0
				? AppLocalizations.of(context)!.todas
				: '${tempDistance.toStringAsFixed(1)} km';

		return Padding(
			padding: MediaQuery.of(context).viewInsets,
			child: SafeArea(
				top: false,
				child: Padding(
					padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Text(
										AppLocalizations.of(context)!.filtros_title,
										style: (Theme.of(context).textTheme.titleLarge ??
														const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))
												.copyWith(color: widget.primaryColor),
									),
									const Spacer(),
									IconButton(
										onPressed: () => Navigator.of(context).pop(),
										icon: const Icon(Icons.close),
										color: widget.primaryColor,
									),
								],
							),
							const SizedBox(height: 16),
							Text(AppLocalizations.of(context)!.categoria_label, style: labelStyle),
							const SizedBox(height: 8),
							buildDropdown(
								currentValue: tempCategory,
								values: widget.categories,
								onChanged: (value) => setState(() => tempCategory = value),
							),
							const SizedBox(height: 16),
							Text(AppLocalizations.of(context)!.actividad_label, style: labelStyle),
							const SizedBox(height: 8),
							buildDropdown(
								currentValue: tempActivity,
								values: widget.activities,
								onChanged: (value) => setState(() => tempActivity = value),
							),
							const SizedBox(height: 16),
							Text(AppLocalizations.of(context)!.distancia_km_label, style: labelStyle),
							const SizedBox(height: 8),
							SliderTheme(
								data: SliderTheme.of(context).copyWith(
									activeTrackColor: widget.primaryColor,
									thumbColor: widget.primaryColor,
								),
								child: Row(
									children: [
										Expanded(
											child: Slider(
												value: tempDistance.clamp(0, widget.computedMaxDistance),
												min: 0,
												max: widget.computedMaxDistance,
												divisions: widget.sliderDivisions > 0 ? widget.sliderDivisions : null,
												label: distanceLabel,
												onChanged: (value) => setState(() => tempDistance = value),
											),
										),
										Text(
											distanceLabel,
											style: const TextStyle(
												fontWeight: FontWeight.w600,
												color: Color(0xFF4D67AE),
											),
										),
									],
								),
							),
							const SizedBox(height: 16),
							
							const SizedBox(height: 24),
							SizedBox(
								width: double.infinity,
								child: ElevatedButton(
									style: ElevatedButton.styleFrom(
										backgroundColor: widget.primaryColor,
										foregroundColor: Colors.white,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(12),
										),
									),
																						onPressed: () async {
																	Navigator.of(context).pop();
																	final cleanCategory = (tempCategory == null || (tempCategory?.trim().isEmpty ?? true)) ? null : tempCategory;
																	final cleanActivity = (tempActivity == null || (tempActivity?.trim().isEmpty ?? true)) ? null : tempActivity;
																	final cleanDistance = (tempDistance <= 0) ? null : tempDistance;
																	context.read<MapBloc>().add(
																		ApplyFilters(
																			category: cleanCategory,
																			activity: cleanActivity,
																			distanceKm: cleanDistance,
																			query: widget.searchController.text.trim(),
																		),
																	);
																						// Analytics: aplicar filtros (categoría + distancia)
																						await AnalyticsService.logAplicarFiltro(
																							categoria: cleanCategory ?? 'todas',
																							distanciaMaxKm: cleanDistance,
																							temporada: (widget.initialSeason == null || (widget.initialSeason?.trim().isEmpty ?? true))
																								? 'todas'
																								: widget.initialSeason,
																						);
																	if (widget.onFiltersApplied != null) {
																		widget.onFiltersApplied!();
																	}
																},
									child: Text(AppLocalizations.of(context)!.aplicar_filtros),
								),
							),
						],
					),
				),
			),
		);
	}
}
