package com.example.belonging_maps_app;

import android.accessibilityservice.AccessibilityService;
import android.app.Instrumentation;
import android.app.UiAutomation;
import android.content.Intent;
import android.graphics.Rect;
import android.os.SystemClock;
import android.view.accessibility.AccessibilityNodeInfo;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;

@RunWith(AndroidJUnit4.class)
public class UmmahMapBrowseAccessibilityTest {
    private static final String[] COMMUNITY_LAYERS = {
            "Business Services",
            "Community Services",
            "Halal Foods",
            "Religious & Cultural",
            "Education"
    };

    private AccessibilityNodeInfo findByDescription(
            AccessibilityNodeInfo node, String description) {
        if (node == null) return null;
        CharSequence actual = node.getContentDescription();
        if (actual != null && description.contentEquals(actual)) return node;
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo found = findByDescription(
                    node.getChild(i), description);
            if (found != null) return found;
        }
        return null;
    }

    private AccessibilityNodeInfo findByTextOrDescription(
            AccessibilityNodeInfo node, String value) {
        if (node == null) return null;
        CharSequence text = node.getText();
        CharSequence description = node.getContentDescription();
        if ((text != null && value.contentEquals(text))
                || (description != null && value.contentEquals(description))) {
            return node;
        }
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo found = findByTextOrDescription(
                    node.getChild(i), value);
            if (found != null) return found;
        }
        return null;
    }

    private AccessibilityNodeInfo findByTextOrDescriptionContaining(
            AccessibilityNodeInfo node, String value) {
        if (node == null) return null;
        CharSequence text = node.getText();
        CharSequence description = node.getContentDescription();
        CharSequence hint = node.getHintText();
        if ((text != null && text.toString().contains(value))
                || (description != null && description.toString().contains(value))
                || (hint != null && hint.toString().contains(value))) {
            return node;
        }
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo found = findByTextOrDescriptionContaining(
                    node.getChild(i), value);
            if (found != null) return found;
        }
        return null;
    }

    private AccessibilityNodeInfo findScrollableNode(AccessibilityNodeInfo node) {
        if (node == null) return null;
        if (node.isScrollable()) return node;
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo found = findScrollableNode(node.getChild(i));
            if (found != null) return found;
        }
        return null;
    }

    private AccessibilityNodeInfo findLocationForCategory(
            AccessibilityNodeInfo node, String category) {
        if (node == null) return null;
        CharSequence description = node.getContentDescription();
        if (description != null && description.toString().startsWith("Open ")
                && description.toString().endsWith(", " + category)) {
            return node;
        }
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo found = findLocationForCategory(
                    node.getChild(i), category);
            if (found != null) return found;
        }
        return null;
    }

    private AccessibilityNodeInfo waitForDescription(
            UiAutomation automation, String description) throws Exception {
        long deadline = SystemClock.uptimeMillis() + 15000;
        while (SystemClock.uptimeMillis() < deadline) {
            AccessibilityNodeInfo found = findByDescription(
                    automation.getRootInActiveWindow(), description);
            if (found != null) return found;
            SystemClock.sleep(250);
        }
        return null;
    }

    private AccessibilityNodeInfo waitForDescriptionWhileScrolling(
            UiAutomation automation, String description, int scrollAction)
            throws Exception {
        long deadline = SystemClock.uptimeMillis() + 15000;
        while (SystemClock.uptimeMillis() < deadline) {
            AccessibilityNodeInfo root = automation.getRootInActiveWindow();
            AccessibilityNodeInfo found = findByDescription(root, description);
            if (found != null) return found;
            AccessibilityNodeInfo scrollable = findScrollableNode(root);
            if (scrollable != null) {
                scrollable.performAction(scrollAction);
            }
            SystemClock.sleep(300);
        }
        return null;
    }

    private AccessibilityNodeInfo waitForLocationForCategory(
            UiAutomation automation, String category) throws Exception {
        long deadline = SystemClock.uptimeMillis() + 15000;
        while (SystemClock.uptimeMillis() < deadline) {
            AccessibilityNodeInfo found = findLocationForCategory(
                    automation.getRootInActiveWindow(), category);
            if (found != null) return found;
            SystemClock.sleep(250);
        }
        return null;
    }

    private AccessibilityNodeInfo waitForFocusedDescription(
            UiAutomation automation, String description) throws Exception {
        long deadline = SystemClock.uptimeMillis() + 15000;
        while (SystemClock.uptimeMillis() < deadline) {
            AccessibilityNodeInfo focused = automation.findFocus(
                    AccessibilityNodeInfo.FOCUS_ACCESSIBILITY);
            if (focused != null && description.contentEquals(
                    focused.getContentDescription())) {
                return focused;
            }
            SystemClock.sleep(100);
        }
        return automation.findFocus(AccessibilityNodeInfo.FOCUS_ACCESSIBILITY);
    }

    private boolean layerHasResult(
            AccessibilityNodeInfo node, String category) {
        if (node == null) return false;
        CharSequence description = node.getContentDescription();
        if (description != null && description.toString().startsWith("Open ")
                && description.toString().endsWith(", " + category)) {
            return true;
        }
        CharSequence text = node.getText();
        if (text != null && ("Could not load locations.".contentEquals(text)
                || "No locations found.".contentEquals(text))) {
            return true;
        }
        for (int i = 0; i < node.getChildCount(); i++) {
            if (layerHasResult(node.getChild(i), category)) return true;
        }
        return false;
    }

    private void waitForLayerLoadToFinish(
            UiAutomation automation, String category) throws Exception {
        long deadline = SystemClock.uptimeMillis() + 15000;
        while (SystemClock.uptimeMillis() < deadline) {
            AccessibilityNodeInfo root = automation.getRootInActiveWindow();
            boolean loading = findByDescription(
                    root, "Loading " + category) != null;
            if (!loading && layerHasResult(root, category)) return;
            SystemClock.sleep(250);
        }
        fail("Timed out waiting for " + category + " locations to finish loading");
    }

    private void activate(UiAutomation automation, String label) throws Exception {
        AccessibilityNodeInfo node = waitForDescription(automation, label);
        assertNotNull("Expected accessibility node: " + label, node);
        assertTrue("Expected node to have a tap action: " + label, node.isClickable());
        assertTrue("ACTION_CLICK should succeed for: " + label,
                node.performAction(AccessibilityNodeInfo.ACTION_CLICK));
    }

    private void activateWhileScrolling(UiAutomation automation, String label)
            throws Exception {
        AccessibilityNodeInfo node = waitForDescriptionWhileScrolling(
                automation, label, AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
        assertNotNull("Expected accessible, scrollable node: " + label, node);
        assertTrue("Expected node to have a tap action: " + label, node.isClickable());
        assertTrue("ACTION_CLICK should succeed for: " + label,
                node.performAction(AccessibilityNodeInfo.ACTION_CLICK));
    }

    private void launchApp(Instrumentation instrumentation) {
        Intent launch = instrumentation.getTargetContext()
                .getPackageManager()
                .getLaunchIntentForPackage(
                        instrumentation.getTargetContext().getPackageName());
        assertNotNull("App launch intent should be available", launch);
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        instrumentation.getTargetContext().startActivity(launch);
    }

    private void openNavigationMenu(UiAutomation automation) throws Exception {
        activate(automation, "Open navigation menu");
        assertNotNull("The navigation drawer should finish opening",
                waitForDescription(automation, "Close navigation menu"));
        automation.waitForIdle(500, 15000);
    }

    private void assertBrowseLocationsOpens(
            UiAutomation automation,
            String directory,
            String map,
            String firstCategory) throws Exception {
        openNavigationMenu(automation);
        activate(automation, directory);
        activateWhileScrolling(automation, map);
        activate(automation, "Browse locations");

        assertNotNull("The browser should expose its first category for " + map,
                waitForDescription(
                        automation, firstCategory + ", Expand locations"));
        assertTrue("Back should dismiss the location browser for " + map,
                automation.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK));
        assertNotNull("The map should still expose Browse locations after closing " + map,
                waitForDescription(automation, "Browse locations"));
    }

    @Test
    public void screenReaderActivationOpensTheSelectedLayer() throws Exception {
        Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
        UiAutomation automation = instrumentation.getUiAutomation(
                UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
        for (String layer : COMMUNITY_LAYERS) {
            Intent launch = instrumentation.getTargetContext()
                    .getPackageManager()
                    .getLaunchIntentForPackage(
                            instrumentation.getTargetContext().getPackageName());
            assertNotNull("App launch intent should be available", launch);
            launch.addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            instrumentation.getTargetContext().startActivity(launch);

            activate(automation, "Community Maps");
            activate(automation, "Ummah Community Map. Ummah Community, Open map");
            activate(automation, "Browse locations");
            automation.waitForIdle(500, 15000);
            String collapsedLabel = layer + ", Expand locations";
            String expandedLabel = layer + ", Collapse locations";
            AccessibilityNodeInfo target = waitForDescription(
                    automation, collapsedLabel);
            assertNotNull("Layer heading should be exposed as its own action: "
                    + layer, target);
            assertTrue("The heading should accept accessibility focus: " + layer,
                    target.performAction(
                            AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS));
            AccessibilityNodeInfo focused = waitForFocusedDescription(
                    automation, collapsedLabel);
            assertNotNull("The Android accessibility focus should resolve", focused);
            assertEquals("Focus should stay on the selected heading: " + layer,
                    collapsedLabel, focused.getContentDescription().toString());
            automation.waitForIdle(500, 15000);
            AccessibilityNodeInfo settledFocused = waitForFocusedDescription(
                    automation, collapsedLabel);
            assertNotNull("Focus should remain on the selected heading: " + layer,
                    settledFocused);
            AccessibilityNodeInfo currentTarget = waitForDescription(
                    automation, collapsedLabel);
            assertNotNull("The selected heading should remain available: " + layer,
                    currentTarget);
            Rect targetBounds = new Rect();
            currentTarget.getBoundsInScreen(targetBounds);
            Rect focusedBounds = new Rect();
            settledFocused.getBoundsInScreen(focusedBounds);
            assertFalse("Target should have non-empty bounds: " + targetBounds,
                    targetBounds.isEmpty());
            assertEquals("Focus bounds should match the selected heading: " + layer,
                    targetBounds, focusedBounds);
            assertTrue("Activating the focused node should succeed: " + layer,
                    settledFocused.performAction(AccessibilityNodeInfo.ACTION_CLICK));
            assertNotNull("The selected layer should report expanded state: " + layer,
                    waitForDescription(automation, expandedLabel));
            for (String otherLayer : COMMUNITY_LAYERS) {
                if (!layer.equals(otherLayer)) {
                    assertNull("Activating " + layer + " must not expand " + otherLayer,
                            findByDescription(automation.getRootInActiveWindow(),
                                    otherLayer + ", Collapse locations"));
                }
            }

            activate(automation, expandedLabel);
            assertNotNull("The selected layer should collapse again: " + layer,
                    waitForDescription(automation, collapsedLabel));
        }
    }

    @Test
    public void somosAndUbuntuMapsExposeBrowsableLocations() throws Exception {
        Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
        UiAutomation automation = instrumentation.getUiAutomation(
                UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);

        launchApp(instrumentation);
        assertBrowseLocationsOpens(
                automation,
                "Campus Maps",
                "SOMOS Campus Map. SOMOS Campus, Open map",
                "Campus locations");

        launchApp(instrumentation);
        assertBrowseLocationsOpens(
                automation,
                "Campus Maps",
                "Ubuntu Campus Map. Ubuntu Campus, Open map",
                "Campus locations");

        launchApp(instrumentation);
        assertBrowseLocationsOpens(
                automation,
                "Community Maps",
                "SOMOS Community Map. SOMOS Community, Open map",
                "Businesses");

        launchApp(instrumentation);
        assertBrowseLocationsOpens(
                automation,
                "Community Maps",
                "Ubuntu Community Map. Ubuntu Community, Open map",
                "Black Owned Businesses");
    }

    @Test
    public void opportunitiesSearchCanBeEnteredAndCleared() throws Exception {
        Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
        UiAutomation automation = instrumentation.getUiAutomation(
                UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
        launchApp(instrumentation);

        openNavigationMenu(automation);
        activate(automation, "Opportunities");
        AccessibilityNodeInfo search = waitForTextOrDescriptionContaining(
                automation, "Search opportunities");
        assertNotNull("Opportunity search should be exposed to Android accessibility", search);
        assertTrue("Opportunity search should accept text input", search.isEditable());

        assertTrue("Search field should receive input focus",
                search.performAction(AccessibilityNodeInfo.ACTION_CLICK));
        instrumentation.sendStringSync("scholarships");
        automation.waitForIdle(500, 15000);

        assertNotNull("Entering a query should expose the clear-search action",
                waitForDescription(automation, "Clear opportunity search"));
        activate(automation, "Clear opportunity search");
        SystemClock.sleep(250);
        assertNull("Clearing the query should hide the clear-search action",
                findByDescription(
                        automation.getRootInActiveWindow(), "Clear opportunity search"));
    }

    @Test
    public void screenReaderCanMoveToNextLayerAfterExpansionAndCollapse()
            throws Exception {
        Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
        UiAutomation automation = instrumentation.getUiAutomation(
                UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
        Intent launch = instrumentation.getTargetContext()
                .getPackageManager()
                .getLaunchIntentForPackage(
                        instrumentation.getTargetContext().getPackageName());
        assertNotNull("App launch intent should be available", launch);
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        instrumentation.getTargetContext().startActivity(launch);

        activate(automation, "Community Maps");
        activate(automation, "Ummah Community Map. Ummah Community, Open map");
        activate(automation, "Browse locations");

        String firstLayer = "Business Services";
        String secondLayer = "Community Services";
        AccessibilityNodeInfo firstHeading = waitForDescription(
                automation, firstLayer + ", Expand locations");
        assertNotNull("The first layer heading should be available", firstHeading);
        assertTrue("The first heading should receive accessibility focus",
                firstHeading.performAction(
                        AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS));
        AccessibilityNodeInfo focusedFirst = waitForFocusedDescription(
                automation, firstLayer + ", Expand locations");
        assertNotNull("The first heading should remain focused", focusedFirst);
        assertTrue("The focused first heading should activate",
                focusedFirst.performAction(AccessibilityNodeInfo.ACTION_CLICK));
        assertNotNull("The first layer should expand",
                waitForDescription(automation, firstLayer + ", Collapse locations"));
        waitForLayerLoadToFinish(automation, firstLayer);
        activate(automation, firstLayer + ", Collapse locations");
        assertNotNull("The first layer should collapse",
                waitForDescription(automation, firstLayer + ", Expand locations"));
        automation.waitForIdle(500, 15000);

        AccessibilityNodeInfo secondHeading = waitForDescription(
                automation, secondLayer + ", Expand locations");
        assertNotNull("The next layer heading should remain available", secondHeading);
        assertTrue("The next heading should receive accessibility focus",
                secondHeading.performAction(
                        AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS));
        AccessibilityNodeInfo focusedSecond = waitForFocusedDescription(
                automation, secondLayer + ", Expand locations");
        assertNotNull("Focus should move to the next layer heading", focusedSecond);
        automation.waitForIdle(500, 15000);
        focusedSecond = waitForFocusedDescription(
                automation, secondLayer + ", Expand locations");
        assertNotNull("Focus should remain on the next layer heading", focusedSecond);
        assertTrue("The next focused heading should activate",
                focusedSecond.performAction(AccessibilityNodeInfo.ACTION_CLICK));
        AccessibilityNodeInfo expandedSecond = waitForDescription(
                automation, secondLayer + ", Collapse locations");
        assertNotNull("The next layer should expand; expanded layers: "
                + expandedLayers(automation), expandedSecond);
        assertNull("Activating the next heading must not reopen the first layer",
                findByDescription(automation.getRootInActiveWindow(),
                        firstLayer + ", Collapse locations"));
    }

    @Test
    public void screenReaderActivatesNextLayerWhileFirstRemainsExpanded()
            throws Exception {
        Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
        UiAutomation automation = instrumentation.getUiAutomation(
                UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
        Intent launch = instrumentation.getTargetContext()
                .getPackageManager()
                .getLaunchIntentForPackage(
                        instrumentation.getTargetContext().getPackageName());
        assertNotNull("App launch intent should be available", launch);
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        instrumentation.getTargetContext().startActivity(launch);

        activate(automation, "Community Maps");
        activate(automation, "Ummah Community Map. Ummah Community, Open map");
        activate(automation, "Browse locations");

        String firstLayer = "Business Services";
        String secondLayer = "Community Services";
        AccessibilityNodeInfo firstHeading = waitForDescription(
                automation, firstLayer + ", Expand locations");
        assertNotNull("The first layer heading should be available", firstHeading);
        assertTrue("The first heading should receive accessibility focus",
                firstHeading.performAction(
                        AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS));
        AccessibilityNodeInfo focusedFirst = waitForFocusedDescription(
                automation, firstLayer + ", Expand locations");
        assertNotNull("The first heading should remain focused", focusedFirst);
        assertTrue("The focused first heading should activate",
                focusedFirst.performAction(AccessibilityNodeInfo.ACTION_CLICK));
        assertNotNull("The first layer should expand",
                waitForDescription(automation, firstLayer + ", Collapse locations"));
        waitForLayerLoadToFinish(automation, firstLayer);

        AccessibilityNodeInfo secondHeading = waitForDescriptionWhileScrolling(
                automation, secondLayer + ", Expand locations",
                AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
        assertNotNull("The next heading should remain available", secondHeading);
        assertTrue("The next heading should receive accessibility focus",
                secondHeading.performAction(
                        AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS));
        AccessibilityNodeInfo focusedSecond = waitForFocusedDescription(
                automation, secondLayer + ", Expand locations");
        assertNotNull("Focus should move to the next heading", focusedSecond);
        automation.waitForIdle(500, 15000);
        focusedSecond = waitForFocusedDescription(
                automation, secondLayer + ", Expand locations");
        assertNotNull("Focus should remain on the next heading", focusedSecond);
        AccessibilityNodeInfo currentSecond = waitForDescription(
                automation, secondLayer + ", Expand locations");
        assertNotNull("The focused heading should still be available", currentSecond);
        Rect currentBounds = new Rect();
        currentSecond.getBoundsInScreen(currentBounds);
        Rect focusedBounds = new Rect();
        focusedSecond.getBoundsInScreen(focusedBounds);
        assertEquals("Focus bounds should match the selected heading",
                currentBounds, focusedBounds);
        assertTrue("The selected next heading should activate",
                focusedSecond.performAction(AccessibilityNodeInfo.ACTION_CLICK));
        assertNotNull("The selected next layer should expand",
                waitForDescription(automation, secondLayer + ", Collapse locations"));
        assertNotNull("Activating the next heading must leave the first expanded",
                waitForDescriptionWhileScrolling(automation,
                        firstLayer + ", Collapse locations",
                        AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD));
    }

    @Test
    public void campusListOpensAndClosesTheSelectedLocation() throws Exception {
        Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
        UiAutomation automation = instrumentation.getUiAutomation(
                UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
        Intent launch = instrumentation.getTargetContext()
                .getPackageManager()
                .getLaunchIntentForPackage(
                        instrumentation.getTargetContext().getPackageName());
        assertNotNull("App launch intent should be available", launch);
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        instrumentation.getTargetContext().startActivity(launch);

        activate(automation, "Campus Maps");
        activate(automation, "Ummah Campus Map. Ummah Campus, Open map");
        activate(automation, "Browse locations");

        String category = "Campus locations";
        String collapsedLabel = category + ", Expand locations";
        String expandedLabel = category + ", Collapse locations";
        AccessibilityNodeInfo heading = waitForDescription(automation, collapsedLabel);
        assertNotNull("The campus layer heading should be available", heading);
        assertTrue("The campus heading should receive accessibility focus",
                heading.performAction(
                        AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS));
        AccessibilityNodeInfo focusedHeading = waitForFocusedDescription(
                automation, collapsedLabel);
        assertNotNull("The campus heading should remain focused", focusedHeading);
        assertTrue("The focused campus heading should activate",
                focusedHeading.performAction(AccessibilityNodeInfo.ACTION_CLICK));
        assertNotNull("The campus layer should expand",
                waitForDescription(automation, expandedLabel));
        waitForLayerLoadToFinish(automation, category);

        AccessibilityNodeInfo location = waitForLocationForCategory(
                automation, category);
        assertNotNull("The campus list should expose a named location", location);
        String locationLabel = location.getContentDescription().toString();
        String locationName = locationLabel.substring(
                "Open ".length(), locationLabel.length() - (", " + category).length());
        assertTrue("The campus location should receive accessibility focus",
                location.performAction(
                        AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS));
        AccessibilityNodeInfo focusedLocation = waitForFocusedDescription(
                automation, locationLabel);
        assertNotNull("The selected campus location should remain focused",
                focusedLocation);
        assertTrue("The focused campus location should activate",
                focusedLocation.performAction(AccessibilityNodeInfo.ACTION_CLICK));
        assertNotNull("The same location should appear in its details card",
                waitForTextOrDescription(automation, locationName));

        activate(automation, "Close location details");
        assertNotNull("Closing details should return to the campus map",
                waitForDescription(automation, "Browse locations"));
        activate(automation, "Browse locations");
        assertTrue("Back should dismiss the location browser",
                automation.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK));
        assertNotNull("The map's Browse locations action should remain available",
                waitForDescription(automation, "Browse locations"));
        assertNull("The campus list heading should no longer be present",
                findByDescription(automation.getRootInActiveWindow(), collapsedLabel));
    }

    private AccessibilityNodeInfo waitForTextOrDescription(
            UiAutomation automation, String value) throws Exception {
        long deadline = SystemClock.uptimeMillis() + 15000;
        while (SystemClock.uptimeMillis() < deadline) {
            AccessibilityNodeInfo found = findByTextOrDescription(
                    automation.getRootInActiveWindow(), value);
            if (found != null) return found;
            SystemClock.sleep(250);
        }
        return null;
    }

    private AccessibilityNodeInfo waitForTextOrDescriptionContaining(
            UiAutomation automation, String value) throws Exception {
        long deadline = SystemClock.uptimeMillis() + 15000;
        while (SystemClock.uptimeMillis() < deadline) {
            AccessibilityNodeInfo found = findByTextOrDescriptionContaining(
                    automation.getRootInActiveWindow(), value);
            if (found != null) return found;
            SystemClock.sleep(250);
        }
        return null;
    }

    private String expandedLayers(UiAutomation automation) {
        StringBuilder expanded = new StringBuilder();
        AccessibilityNodeInfo root = automation.getRootInActiveWindow();
        for (String layer : COMMUNITY_LAYERS) {
            if (findByDescription(root, layer + ", Collapse locations") != null) {
                if (expanded.length() > 0) expanded.append(", ");
                expanded.append(layer);
            }
        }
        return expanded.length() == 0 ? "none" : expanded.toString();
    }

}
