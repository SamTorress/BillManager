<?php

use App\Http\Controllers\BillController;
use Illuminate\Support\Facades\Route;
use App\Http\Middleware\VerifyKeycloakToken;

Route::prefix('restapi')->middleware(VerifyKeycloakToken::class)->group(function () {
    Route::apiResource('bills', BillController::class);
});


// Test route to verify Keycloak token
Route::middleware(VerifyKeycloakToken::class)->get('/test-auth', function (\Illuminate\Http\Request $request) {
    return response()->json([
        'username' => $request->attributes->get('jwt_username'),
        'roles' => $request->attributes->get('jwt_roles'),
    ]);
});
