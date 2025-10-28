import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/map_bloc.dart';
import '../events/map_event.dart';

class FilterModal extends StatefulWidget {
  final List<String> categories;
  final List<String> seasons;
  final double computedMaxDistance;
  final int sliderDivisions;
  final String? initialCategory;
  final double initialDistance;
  final String? initialSeason;
  final Color primaryColor;
  final TextEditingController searchController;
  final void Function()? onFiltersApplied;

  const FilterModal({
    super.key,
    required this.categories,
    required this.seasons,
    required this.computedMaxDistance,
    required this.sliderDivisions,
    required this.initialCategory,
    required this.initialDistance,
    required this.initialSeason,
    required this.primaryColor,
    required this.searchController,
    this.onFiltersApplied,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late String? tempCategory;
  late double tempDistance;
  late String? tempSeason;

  @override
  void initState() {
    super.initState();
    tempCategory = widget.initialCategory;
    tempDistance = widget.initialDistance;
    tempSeason = widget.initialSeason;
  }

  Widget buildDropdown({
    required String? currentValue,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        hintText: 'Todas',
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
          hint: const Text('Todas'),
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            ...values.map(
              (value) => DropdownMenuItem(value: value, child: Text(value)),
            ),
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
        ? 'Todas'
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
                    'Filtros',
                    style:
                        (Theme.of(context).textTheme.titleLarge ??
                                const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ))
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
              Text('Categoría', style: labelStyle),
              const SizedBox(height: 8),
              buildDropdown(
                currentValue: tempCategory,
                values: widget.categories,
                onChanged: (value) => setState(() => tempCategory = value),
              ),
              const SizedBox(height: 16),
              Text('Distancia (km)', style: labelStyle),
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
                        value: tempDistance.clamp(
                          0,
                          widget.computedMaxDistance,
                        ),
                        min: 0,
                        max: widget.computedMaxDistance,
                        divisions: widget.sliderDivisions > 0
                            ? widget.sliderDivisions
                            : null,
                        label: distanceLabel,
                        onChanged: (value) =>
                            setState(() => tempDistance = value),
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
              Text('Temporada', style: labelStyle),
              const SizedBox(height: 8),
              buildDropdown(
                currentValue: tempSeason,
                values: widget.seasons,
                onChanged: (value) => setState(() => tempSeason = value),
              ),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    final cleanCategory =
                        (tempCategory == null ||
                            tempCategory!.trim().isEmpty ||
                            tempCategory == 'Todas')
                        ? null
                        : tempCategory;
                    final cleanSeason =
                        (tempSeason == null ||
                            tempSeason!.trim().isEmpty ||
                            tempSeason == 'Todas')
                        ? null
                        : tempSeason;
                    final cleanDistance = (tempDistance <= 0)
                        ? null
                        : tempDistance;
                    context.read<MapBloc>().add(
                      ApplyFilters(
                        category: cleanCategory,
                        distanceKm: cleanDistance,
                        season: cleanSeason,
                        query: widget.searchController.text.trim(),
                      ),
                    );
                    if (widget.onFiltersApplied != null) {
                      widget.onFiltersApplied!();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Filtros aplicados ✅'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
