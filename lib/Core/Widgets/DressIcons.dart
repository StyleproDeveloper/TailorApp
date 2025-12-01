import 'package:flutter/material.dart';
import '../Constants/ColorPalatte.dart';

class DressIcons {
  // Map of dress types to their corresponding icons
  static const Map<String, IconData> _dressIconMap = {
    // Formal wear
    'blouse': Icons.checkroom, // Changed from woman to checkroom (clothing icon)
    'blazer': Icons.checkroom, // Changed from business_center to checkroom
    'suit': Icons.checkroom, // Changed from business_center to checkroom
    'coat': Icons.checkroom, // Changed from outbond to checkroom
    'jacket': Icons.checkroom,
    
    // Traditional wear
    'kurta': Icons.checkroom, // Changed from self_improvement to checkroom
    'kurti': Icons.checkroom, // Changed from self_improvement to checkroom
    'saree': Icons.checkroom, // Changed from woman to checkroom
    'lehenga': Icons.checkroom, // Changed from celebration to checkroom
    'anarkali': Icons.checkroom, // Changed from celebration to checkroom
    'salwar': Icons.checkroom, // Changed from self_improvement to checkroom
    'churidar': Icons.checkroom, // Changed from self_improvement to checkroom
    'palazzo': Icons.checkroom, // Changed from self_improvement to checkroom
    
    // Casual wear
    'shirt': Icons.checkroom,
    'top': Icons.checkroom,
    't-shirt': Icons.checkroom,
    'tshirt': Icons.checkroom,
    'dress': Icons.checkroom, // Changed from woman to checkroom
    'gown': Icons.checkroom, // Changed from celebration to checkroom
    'maxi': Icons.checkroom, // Changed from woman to checkroom
    
    // Bottom wear
    'pant': Icons.checkroom, // Changed from straighten to checkroom
    'pants': Icons.checkroom, // Changed from straighten to checkroom
    'trouser': Icons.checkroom, // Changed from straighten to checkroom
    'trousers': Icons.checkroom, // Changed from straighten to checkroom
    'jeans': Icons.checkroom, // Changed from straighten to checkroom
    'skirt': Icons.checkroom, // Changed from woman to checkroom
    'shorts': Icons.checkroom, // Changed from straighten to checkroom
    'leggings': Icons.checkroom, // Changed from straighten to checkroom
    
    // Inner wear
    'bra': Icons.checkroom, // Changed from favorite_border to checkroom
    'petticoat': Icons.checkroom, // Changed from woman to checkroom
    'slip': Icons.checkroom, // Changed from woman to checkroom
    
    // Accessories
    'dupatta': Icons.checkroom, // Changed from waves to checkroom
    'scarf': Icons.checkroom, // Changed from waves to checkroom
    'stole': Icons.checkroom, // Changed from waves to checkroom
    'shawl': Icons.checkroom, // Changed from waves to checkroom
    
    // Kids wear
    'frock': Icons.checkroom, // Changed from child_care to checkroom
    'romper': Icons.checkroom, // Changed from child_care to checkroom
    'jumpsuit': Icons.checkroom, // Changed from child_care to checkroom
    
    // Men's wear
    'dhoti': Icons.checkroom, // Changed from man to checkroom
    'lungi': Icons.checkroom, // Changed from man to checkroom
    'veshti': Icons.checkroom, // Changed from man to checkroom
    
    // Special occasion
    'wedding': Icons.checkroom, // Changed from favorite to checkroom
    'party': Icons.checkroom, // Changed from celebration to checkroom
    'evening': Icons.checkroom, // Changed from nights_stay to checkroom
    
    // Work wear
    'uniform': Icons.checkroom, // Changed from work to checkroom
    'apron': Icons.checkroom, // Changed from kitchen to checkroom
    
    // Default fallback
    'default': Icons.checkroom,
  };

  // Get icon for a dress type
  static IconData getIconForDressType(String? dressType) {
    if (dressType == null || dressType.isEmpty) {
      return _dressIconMap['default']!;
    }
    
    // Convert to lowercase for case-insensitive matching
    String lowerDressType = dressType.toLowerCase().trim();
    
    // Direct match first
    if (_dressIconMap.containsKey(lowerDressType)) {
      return _dressIconMap[lowerDressType]!;
    }
    
    // Partial match - check if any key contains the dress type or vice versa
    for (String key in _dressIconMap.keys) {
      if (lowerDressType.contains(key) || key.contains(lowerDressType)) {
        return _dressIconMap[key]!;
      }
    }
    
    // Return default icon if no match found
    return _dressIconMap['default']!;
  }

  // Get color based on dress category
  static Color getColorForDressType(String? dressType) {
    if (dressType == null || dressType.isEmpty) {
      return ColorPalatte.primary;
    }
    
    String lowerDressType = dressType.toLowerCase().trim();
    
    // Traditional wear - Golden/Orange theme
    if (['kurta', 'kurti', 'saree', 'lehenga', 'anarkali', 'salwar', 'churidar', 'palazzo', 'dhoti', 'lungi', 'veshti'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.orange.shade700;
    }
    
    // Formal wear - Blue theme
    if (['blazer', 'suit', 'coat', 'jacket', 'shirt', 'trouser', 'trousers', 'uniform'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.blue.shade700;
    }
    
    // Party/Celebration wear - Purple theme
    if (['gown', 'dress', 'party', 'wedding', 'evening', 'celebration'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.purple.shade700;
    }
    
    // Casual wear - Green theme
    if (['top', 't-shirt', 'tshirt', 'jeans', 'shorts', 'casual'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.green.shade700;
    }
    
    // Kids wear - Pink theme
    if (['frock', 'romper', 'jumpsuit', 'child'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.pink.shade700;
    }
    
    // Women's specific - Red theme
    if (['blouse', 'woman', 'lady', 'female'].any((item) => 
        lowerDressType.contains(item) || item.contains(lowerDressType))) {
      return Colors.red.shade700;
    }
    
    // Default color
    return ColorPalatte.primary;
  }
}

// Custom widget for dress icons
class DressIconWidget extends StatelessWidget {
  final String? dressType;
  final String? imageUrl; // URL for dress type image
  final double size;
  final bool showBackground;
  final Color? backgroundColor;
  final Color? iconColor;
  
  const DressIconWidget({
    Key? key,
    required this.dressType,
    this.imageUrl,
    this.size = 40.0,
    this.showBackground = true,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final IconData icon = DressIcons.getIconForDressType(dressType);
    final Color bgColor = backgroundColor ?? DressIcons.getColorForDressType(dressType);
    final Color icColor = iconColor ?? Colors.white;
    
    // If imageUrl is provided, show image instead of icon
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.network(
            imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails to load
              return _buildIconWidget(icon, bgColor, icColor);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: size * 0.5,
                  height: size * 0.5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    // Show icon if no imageUrl
    return _buildIconWidget(icon, bgColor, icColor);
  }
  
  Widget _buildIconWidget(IconData icon, Color bgColor, Color icColor) {
    if (showBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: icColor,
          size: size * 0.6,
        ),
      );
    } else {
      return Icon(
        icon,
        color: bgColor,
        size: size,
      );
    }
  }
}