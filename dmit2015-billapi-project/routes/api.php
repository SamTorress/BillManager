<?php

use App\Http\Controllers\BillController;
use Illuminate\Support\Facades\Route;

Route::prefix('restapi')->group(function () {
    Route::apiResource('bills', BillController::class);
});
